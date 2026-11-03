package com.fuli.invest.service;

import com.fuli.invest.dto.response.AllocationDTO;
import com.fuli.invest.dto.response.DashboardSummaryResponse;
import com.fuli.invest.dto.response.EquityPointDTO;
import com.fuli.invest.dto.response.PositionSummaryResponse;
import com.fuli.invest.entity.Account;
import com.fuli.invest.entity.DailyEquitySnapshot;
import com.fuli.invest.entity.InstrumentType;
import com.fuli.invest.entity.Position;
import com.fuli.invest.entity.Trade;
import com.fuli.invest.repository.AccountRepository;
import com.fuli.invest.repository.DailyEquitySnapshotRepository;
import com.fuli.invest.repository.PositionRepository;
import com.fuli.invest.repository.TradeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class DashboardService {

    private final DailyEquitySnapshotRepository snapshotRepository;
    private final PositionRepository positionRepository;
    private final AccountRepository accountRepository;
    private final TradeRepository tradeRepository;
    private final PositionService positionService;

    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ISO_LOCAL_DATE;

    public DashboardSummaryResponse summary(Long userId, String period) {
        LocalDate today = LocalDate.now();
        LocalDate from = switch (period == null ? "month" : period) {
            case "day" -> today.minusDays(1);
            case "week" -> today.minusWeeks(1);
            case "month" -> today.minusMonths(1);
            case "year" -> today.minusYears(1);
            default -> today.minusYears(3); // "all"：MVP 阶段用 3 年兜底
        };

        List<DailyEquitySnapshot> snapshots =
                snapshotRepository.findByUserIdAndSnapDateBetweenOrderBySnapDateAsc(userId, from, today);

        List<EquityPointDTO> equityCurve = snapshots.stream()
                .map(s -> new EquityPointDTO(s.getSnapDate().format(DATE_FMT), s.getTotalAssets()))
                .collect(Collectors.toList());

        BigDecimal totalAssets = snapshots.isEmpty()
                ? BigDecimal.ZERO
                : snapshots.get(snapshots.size() - 1).getTotalAssets();

        BigDecimal todayPnl = BigDecimal.ZERO;
        BigDecimal todayPct = BigDecimal.ZERO;
        if (snapshots.size() >= 2) {
            BigDecimal prev = snapshots.get(snapshots.size() - 2).getTotalAssets();
            todayPnl = totalAssets.subtract(prev);
            todayPct = prev.compareTo(BigDecimal.ZERO) == 0
                    ? BigDecimal.ZERO
                    : todayPnl.divide(prev, 4, RoundingMode.HALF_UP).multiply(BigDecimal.valueOf(100));
        }

        // 资产分布：股票按市值，期货/期权按保证金占用近似（未接入行情前的简化口径，见 PositionService 类注释）
        List<Position> positions = positionRepository.findByUserIdOrderByUpdatedAtDesc(userId);
        Map<InstrumentType, BigDecimal> byType = positions.stream().collect(Collectors.groupingBy(
                Position::getInstrumentType,
                Collectors.reducing(BigDecimal.ZERO,
                        p -> p.getInstrumentType() == InstrumentType.STOCK
                                ? p.getQuantity().multiply(p.getCurrentPrice() != null ? p.getCurrentPrice() : p.getCostPrice())
                                : (p.getMarginAmount() != null ? p.getMarginAmount() : BigDecimal.ZERO),
                        BigDecimal::add)));
        BigDecimal allocationTotal = byType.values().stream().reduce(BigDecimal.ZERO, BigDecimal::add);
        List<AllocationDTO> allocation = List.of(InstrumentType.STOCK, InstrumentType.FUTURE, InstrumentType.OPTION)
                .stream()
                .map(t -> {
                    BigDecimal v = byType.getOrDefault(t, BigDecimal.ZERO);
                    BigDecimal pct = allocationTotal.compareTo(BigDecimal.ZERO) == 0
                            ? BigDecimal.ZERO
                            : v.divide(allocationTotal, 4, RoundingMode.HALF_UP).multiply(BigDecimal.valueOf(100));
                    return new AllocationDTO(t.name(), labelOf(t), pct.setScale(0, RoundingMode.HALF_UP));
                })
                .collect(Collectors.toList());

        // 本周胜率
        LocalDateTime weekAgo = LocalDateTime.now().minusDays(7);
        List<Trade> weekTrades = tradeRepository.findByUserIdAndTradeTimeBetween(userId, weekAgo, LocalDateTime.now())
                .stream().filter(t -> t.getPnlAmount() != null).collect(Collectors.toList());
        BigDecimal winRateWeek = weekTrades.isEmpty()
                ? BigDecimal.ZERO
                : BigDecimal.valueOf(weekTrades.stream().filter(t -> t.getPnlAmount().compareTo(BigDecimal.ZERO) > 0).count())
                    .divide(BigDecimal.valueOf(weekTrades.size()), 4, RoundingMode.HALF_UP)
                    .multiply(BigDecimal.valueOf(100)).setScale(1, RoundingMode.HALF_UP);

        PositionSummaryResponse positionSummary = positionService.summary(userId, null);

        Map<Long, String> accountNames = accountRepository.findByUserIdOrderByCreatedAtAsc(userId).stream()
                .collect(Collectors.toMap(Account::getId, Account::getName));

        List<Trade> recent = tradeRepository.findTop5ByUserIdOrderByTradeTimeDesc(userId);

        return DashboardSummaryResponse.builder()
                .totalAssets(totalAssets)
                .todayPnl(todayPnl)
                .todayPct(todayPct)
                .period(period == null ? "month" : period)
                .equityCurve(equityCurve)
                .allocation(allocation)
                .winRateWeek(winRateWeek)
                .positionCount(positions.size())
                .marginUsageRate(positionSummary.getMarginUsageRate())
                .recentTrades(recent.stream()
                        .map(t -> TradeMapper.toDto(t, t.getAccountId() == null ? null : accountNames.get(t.getAccountId())))
                        .collect(Collectors.toList()))
                .build();
    }

    private String labelOf(InstrumentType type) {
        return switch (type) {
            case STOCK -> "股票";
            case FUTURE -> "期货";
            case OPTION -> "期权";
        };
    }
}
