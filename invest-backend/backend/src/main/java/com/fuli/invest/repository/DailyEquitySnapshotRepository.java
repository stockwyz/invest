package com.fuli.invest.repository;

import com.fuli.invest.entity.DailyEquitySnapshot;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface DailyEquitySnapshotRepository extends JpaRepository<DailyEquitySnapshot, Long> {

    List<DailyEquitySnapshot> findByUserIdAndSnapDateBetweenOrderBySnapDateAsc(
            Long userId, LocalDate from, LocalDate to);

    Optional<DailyEquitySnapshot> findByUserIdAndSnapDate(Long userId, LocalDate snapDate);

    Optional<DailyEquitySnapshot> findTopByUserIdOrderBySnapDateDesc(Long userId);
}
