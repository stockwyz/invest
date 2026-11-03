package com.fuli.invest.common;

import lombok.Getter;

/** 业务异常：Controller 层不用到处 try/catch，统一交给 GlobalExceptionHandler 包装成 ApiResponse。 */
@Getter
public class BizException extends RuntimeException {

    private final int code;

    public BizException(String message) {
        this(40000, message);
    }

    public BizException(int code, String message) {
        super(message);
        this.code = code;
    }
}
