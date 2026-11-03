package com.fuli.invest.dto.request;

import com.fuli.invest.entity.InstrumentType;
import com.fuli.invest.entity.TradeDirection;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/** 新增/编辑一笔交易的请求体，对应"记一笔交易"表单。同一结构用于 POST 和 PUT。 */
@Getter
@Setter
public class TradeSaveRequest {

    private Long accountId;

    @NotNull(message = "不能为空")
    private InstrumentType instrumentType;

    @NotBlank(message = "不能为空")
    private String code;

    @NotBlank(message = "不能为空")
    private String name;

    @NotNull(message = "不能为空")
    private TradeDirection direction;

    @NotNull(message = "不能为空")
    @DecimalMin(value = "0.0001", message = "必须大于 0")
    private BigDecimal quantity;

    @NotNull(message = "不能为空")
    @DecimalMin(value = "0", message = "不能为负数")
    private BigDecimal price;

    /** 平仓价：股票不使用；期货/期权已平仓时填写 */
    private BigDecimal closePrice;

    /** 行权价：仅期权 */
    private BigDecimal strikePrice;

    /** 到期日：期货/期权 */
    private LocalDate expireDate;

    /** 保证金：仅期货，缺省时由服务层按合约名义价值估算 */
    private BigDecimal marginAmount;

    private BigDecimal fee;

    @NotNull(message = "不能为空")
    private LocalDateTime tradeTime;

    private String note;

    private List<String> tagNames;
}
