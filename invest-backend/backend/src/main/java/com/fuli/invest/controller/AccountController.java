package com.fuli.invest.controller;

import com.fuli.invest.common.ApiResponse;
import com.fuli.invest.common.CurrentUserProvider;
import com.fuli.invest.entity.Account;
import com.fuli.invest.repository.AccountRepository;
import lombok.AllArgsConstructor;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.util.List;

/** 供"记一笔交易"表单的"所属账户"下拉选择使用。 */
@RestController
@RequestMapping("/api/accounts")
@RequiredArgsConstructor
public class AccountController {

    private final AccountRepository accountRepository;
    private final CurrentUserProvider currentUserProvider;

    @GetMapping
    public ApiResponse<List<AccountBrief>> list() {
        Long userId = currentUserProvider.currentUserId();
        List<AccountBrief> items = accountRepository.findByUserIdOrderByCreatedAtAsc(userId).stream()
                .map(a -> new AccountBrief(a.getId(), a.getName(), a.getAccountType().name(), a.getAvailableCash()))
                .toList();
        return ApiResponse.ok(items);
    }

    @AllArgsConstructor
    public static class AccountBrief {
        public Long id;
        public String name;
        public String accountType;
        public BigDecimal availableCash;
    }
}
