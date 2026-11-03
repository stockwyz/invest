package com.fuli.invest.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;

/**
 * 交易记录：宽表设计，一行覆盖股票/期货/期权三类字段。
 * instrumentType 决定哪些字段有意义（见各字段注释），未使用的字段留空。
 * 这样"记一笔交易"新增/编辑接口不用为每个品种单独建表，前端切换 Tab 时
 * 也只是切换要展示/校验的字段子集。
 */
@Entity
@Table(name = "trade")
@Getter
@Setter
@NoArgsConstructor
public class Trade {

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

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private TradeDirection direction;

    /** 数量：股数 / 期货手数 / 期权张数 */
    @Column(nullable = false, precision = 18, scale = 4)
    private BigDecimal quantity;

    /** 成交价 / 期货开仓价 / 期权权利金 */
    @Column(nullable = false, precision = 18, scale = 4)
    private BigDecimal price;

    /** 平仓价（已平仓时填写，用于计算已实现盈亏） */
    @Column(name = "close_price", precision = 18, scale = 4)
    private BigDecimal closePrice;

    /** 行权价（期权专用） */
    @Column(name = "strike_price", precision = 18, scale = 4)
    private BigDecimal strikePrice;

    /** 到期日（期货/期权专用） */
    @Column(name = "expire_date")
    private LocalDate expireDate;

    /** 保证金占用（期货专用） */
    @Column(name = "margin_amount", precision = 18, scale = 2)
    private BigDecimal marginAmount;

    /** 杠杆倍数（期货，= 合约价值 / 保证金，由服务层写入时自动计算） */
    @Column(precision = 8, scale = 2)
    private BigDecimal leverage;

    /** 手续费/印花税/过户费合计 */
    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal fee = BigDecimal.ZERO;

    @Column(name = "pnl_amount", precision = 18, scale = 2)
    private BigDecimal pnlAmount;

    @Column(name = "pnl_pct", precision = 8, scale = 4)
    private BigDecimal pnlPct;

    @Column(name = "trade_time", nullable = false)
    private LocalDateTime tradeTime;

    @Lob
    @Column
    private String note;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
        name = "trade_tag",
        joinColumns = @JoinColumn(name = "trade_id"),
        inverseJoinColumns = @JoinColumn(name = "tag_id")
    )
    private Set<Tag> tags = new HashSet<>();

    @PrePersist
    void onCreate() {
        LocalDateTime now = LocalDateTime.now();
        this.createdAt = now;
        this.updatedAt = now;
    }

    @PreUpdate
    void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }
}
