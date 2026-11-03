package com.fuli.invest.controller;

import com.fuli.invest.common.ApiResponse;
import com.fuli.invest.common.CurrentUserProvider;
import com.fuli.invest.dto.response.AnalyticsSummaryResponse;
import com.fuli.invest.service.AnalyticsService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** 对应数据分析页：总盈亏/胜率/盈亏比/最大回撤等指标 + 资金曲线 + 盈亏贡献 + 月度盈亏。 */
@RestController
@RequestMapping("/api/analytics")
@RequiredArgsConstructor
public class AnalyticsController {

    private final AnalyticsService analyticsService;
    private final CurrentUserProvider currentUserProvider;

    @GetMapping("/summary")
    public ApiResponse<AnalyticsSummaryResponse> summary(
            @RequestParam(required = false, defaultValue = "year") String range) {
        Long userId = currentUserProvider.currentUserId();
        return ApiResponse.ok(analyticsService.summary(userId, range));
    }
}
