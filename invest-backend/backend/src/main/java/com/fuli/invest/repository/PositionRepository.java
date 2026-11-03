package com.fuli.invest.repository;

import com.fuli.invest.entity.InstrumentType;
import com.fuli.invest.entity.Position;
import com.fuli.invest.entity.TradeDirection;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PositionRepository extends JpaRepository<Position, Long> {

    List<Position> findByUserIdOrderByUpdatedAtDesc(Long userId);

    List<Position> findByUserIdAndInstrumentTypeOrderByUpdatedAtDesc(Long userId, InstrumentType instrumentType);

    Optional<Position> findByUserIdAndAccountIdAndInstrumentTypeAndCodeAndDirection(
            Long userId, Long accountId, InstrumentType instrumentType, String code, TradeDirection direction);
}
