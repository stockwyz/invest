package com.fuli.invest.controller;

import com.fuli.invest.common.ApiResponse;
import com.fuli.invest.common.CurrentUserProvider;
import com.fuli.invest.dto.response.PositionSummaryResponse;
import com.fuli.invest.entity.InstrumentType;
import com.fuli.invest.service.PositionService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** 对应持仓管理页：汇总卡片 + 按品种分类的持仓列表。 */
@RestController
@RequestMapping("/api/positions")
@RequiredArgsConstructor
public class PositionController {

    private final PositionService positionService;
    private final CurrentUserProvider currentUserProvider;

    @GetMapping
    public ApiResponse<PositionSummaryResponse> list(@RequestParam(required = false) InstrumentType type) {
        Long userId = currentUserProvider.currentUserId();
        return ApiResponse.ok(positionService.summary(userId, type));
    }
}
