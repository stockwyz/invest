package com.fuli.invest.controller;

import com.fuli.invest.common.ApiResponse;
import com.fuli.invest.common.CurrentUserProvider;
import com.fuli.invest.dto.response.DashboardSummaryResponse;
import com.fuli.invest.service.DashboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

/** 对应首页仪表盘：总资产、今日盈亏、资金曲线、资产分布、迷你指标、最近交易。 */
@RestController
@RequestMapping("/api/dashboard")
@RequiredArgsConstructor
public class DashboardController {

    private final DashboardService dashboardService;
    private final CurrentUserProvider currentUserProvider;

    @GetMapping("/summary")
    public ApiResponse<DashboardSummaryResponse> summary(
            @RequestParam(required = false, defaultValue = "month") String period) {
        Long userId = currentUserProvider.currentUserId();
        return ApiResponse.ok(dashboardService.summary(userId, period));
    }
}
