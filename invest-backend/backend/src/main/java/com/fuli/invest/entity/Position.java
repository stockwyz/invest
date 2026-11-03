package com.fuli.invest.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 当前持仓：由 PositionService 在每次交易新增/编辑/删除后按加权平均法重新聚合维护，
 * 而不是每次查询都对全部历史交易做汇总，换取持仓页查询性能。
 * currentPrice 目前由人工在持仓详情里维护；接入行情数据源后可由后台任务定时刷新。
 */
@Entity
@Table(name = "trade_position")
@Getter
@Setter
@NoArgsConstructor
public class Position {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "account_id")
    private Long accountId;

    @Enumerated(EnumType.STRING)
    @Column(name = "instrument_type", nullable = false, length = 8)
    private InstrumentType instrumentType;

    @Column(nullable = false, length = 32)
    private String code;

    @Column(nullable = false, length = 64)
    private String name;

    /** 持仓方向：股票恒为 LONG；期货/期权为 LONG（多/买方）或 SHORT（空/卖方义务仓）。 */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private TradeDirection direction;

    @Column(nullable = false, precision = 18, scale = 4)
    private BigDecimal quantity;

    @Column(name = "cost_price", nullable = false, precision = 18, scale = 4)
    private BigDecimal costPrice;

    @Column(name = "current_price", precision = 18, scale = 4)
    private BigDecimal currentPrice;

    @Column(name = "margin_amount", precision = 18, scale = 2)
    private BigDecimal marginAmount;

    @Column(name = "expire_date")
    private LocalDate expireDate;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    @PreUpdate
    void touch() {
        this.updatedAt = LocalDateTime.now();
    }
}
