package com.fuli.invest.controller;

import com.fuli.invest.common.ApiResponse;
import com.fuli.invest.common.CurrentUserProvider;
import com.fuli.invest.dto.request.TradeSaveRequest;
import com.fuli.invest.dto.response.PageResult;
import com.fuli.invest.dto.response.TradeDTO;
import com.fuli.invest.entity.InstrumentType;
import com.fuli.invest.service.TradeService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

/** 对应交易记录列表 + 记一笔交易（新增/编辑）。 */
@RestController
@RequestMapping("/api/trades")
@RequiredArgsConstructor
public class TradeController {

    private final TradeService tradeService;
    private final CurrentUserProvider currentUserProvider;

    @GetMapping
    public ApiResponse<PageResult<TradeDTO>> list(
            @RequestParam(required = false) InstrumentType type,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Long userId = currentUserProvider.currentUserId();
        return ApiResponse.ok(tradeService.list(userId, type, page, size));
    }

    @GetMapping("/{id}")
    public ApiResponse<TradeDTO> get(@PathVariable Long id) {
        Long userId = currentUserProvider.currentUserId();
        return ApiResponse.ok(tradeService.get(userId, id));
    }

    @PostMapping
    public ApiResponse<TradeDTO> create(@Valid @RequestBody TradeSaveRequest req) {
        Long userId = currentUserProvider.currentUserId();
        return ApiResponse.ok(tradeService.create(userId, req));
    }

    @PutMapping("/{id}")
    public ApiResponse<TradeDTO> update(@PathVariable Long id, @Valid @RequestBody TradeSaveRequest req) {
        Long userId = currentUserProvider.currentUserId();
        return ApiResponse.ok(tradeService.update(userId, id, req));
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@PathVariable Long id) {
        Long userId = currentUserProvider.currentUserId();
        tradeService.delete(userId, id);
        return ApiResponse.ok(null);
    }
}
