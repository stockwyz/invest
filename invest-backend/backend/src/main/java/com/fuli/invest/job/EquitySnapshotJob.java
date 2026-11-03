package com.fuli.invest.job;

import com.fuli.invest.dto.response.PositionSummaryResponse;
import com.fuli.invest.entity.Account;
import com.fuli.invest.entity.DailyEquitySnapshot;
import com.fuli.invest.entity.SysUser;
import com.fuli.invest.repository.AccountRepository;
import com.fuli.invest.repository.DailyEquitySnapshotRepository;
import com.fuli.invest.service.PositionService;
import jakarta.persistence.EntityManager;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * 每日收盘后写入一条资金快照，作为首页/分析页资金曲线的数据源。
 * MVP 阶段只有一个演示用户（见 CurrentUserProvider），生产环境应遍历 sys_user 表逐个生成。
 */
@Component
@RequiredArgsConstructor
public class EquitySnapshotJob {

    private final AccountRepository accountRepository;
    private final DailyEquitySnapshotRepository snapshotRepository;
    private final PositionService positionService;
    private final EntityManager entityManager;

    /** 每个交易日 15:30 执行一次；cron 表达式：秒 分 时 日 月 周。 */
    @Scheduled(cron = "0 30 15 * * MON-FRI")
    @Transactional
    public void run() {
        List<SysUser> users = entityManager.createQuery("select u from SysUser u", SysUser.class).getResultList();
        for (SysUser user : users) {
            snapshotForUser(user.getId());
        }
    }

    @Transactional
    public void snapshotForUser(Long userId) {
        BigDecimal availableCash = accountRepository.findByUserIdOrderByCreatedAtAsc(userId).stream()
                .map(Account::getAvailableCash).reduce(BigDecimal.ZERO, BigDecimal::add);
        PositionSummaryResponse positionSummary = positionService.summary(userId, null);
        BigDecimal positionValue = positionSummary.getTotalMarketValue();
        BigDecimal totalAssets = availableCash.add(positionValue);

        LocalDate today = LocalDate.now();
        DailyEquitySnapshot snapshot = snapshotRepository.findByUserIdAndSnapDate(userId, today)
                .orElseGet(DailyEquitySnapshot::new);
        snapshot.setUserId(userId);
        snapshot.setSnapDate(today);
        snapshot.setAvailableCash(availableCash);
        snapshot.setPositionValue(positionValue);
        snapshot.setTotalAssets(totalAssets);
        snapshotRepository.save(snapshot);
    }
}
