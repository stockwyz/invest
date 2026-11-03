package com.fuli.invest.controller;

import com.fuli.invest.common.ApiResponse;
import com.fuli.invest.common.CurrentUserProvider;
import com.fuli.invest.job.EquitySnapshotJob;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** 本地开发/联调用：手动触发一次"今日资金快照"，不用等到 15:30 的定时任务。生产环境建议移除或加鉴权。 */
@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminController {

    private final EquitySnapshotJob equitySnapshotJob;
    private final CurrentUserProvider currentUserProvider;

    @PostMapping("/snapshot/run")
    public ApiResponse<Void> runSnapshot() {
        equitySnapshotJob.snapshotForUser(currentUserProvider.currentUserId());
        return ApiResponse.ok(null);
    }
}
