package com.fuli.invest.repository;

import com.fuli.invest.entity.InstrumentType;
import com.fuli.invest.entity.Trade;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;

public interface TradeRepository extends JpaRepository<Trade, Long> {

    Page<Trade> findByUserIdOrderByTradeTimeDesc(Long userId, Pageable pageable);

    Page<Trade> findByUserIdAndInstrumentTypeOrderByTradeTimeDesc(
            Long userId, InstrumentType instrumentType, Pageable pageable);

    List<Trade> findByUserIdAndTradeTimeBetweenOrderByTradeTimeAsc(
            Long userId, LocalDateTime from, LocalDateTime to);

    List<Trade> findTop5ByUserIdOrderByTradeTimeDesc(Long userId);

    List<Trade> findByUserIdAndTradeTimeBetween(Long userId, LocalDateTime from, LocalDateTime to);
}
