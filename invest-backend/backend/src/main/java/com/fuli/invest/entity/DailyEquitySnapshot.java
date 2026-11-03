package com.fuli.invest.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/** 每日资金快照，驱动首页与分析页的资金曲线；由 EquitySnapshotJob 每日写入一条。 */
@Entity
@Table(name = "daily_equity_snapshot")
@Getter
@Setter
@NoArgsConstructor
public class DailyEquitySnapshot {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "snap_date", nullable = false)
    private LocalDate snapDate;

    @Column(name = "total_assets", nullable = false, precision = 18, scale = 2)
    private BigDecimal totalAssets;

    @Column(name = "available_cash", nullable = false, precision = 18, scale = 2)
    private BigDecimal availableCash;

    @Column(name = "position_value", nullable = false, precision = 18, scale = 2)
    private BigDecimal positionValue;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    void onCreate() {
        this.createdAt = LocalDateTime.now();
    }
}
