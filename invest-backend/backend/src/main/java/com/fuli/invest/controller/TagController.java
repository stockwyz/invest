package com.fuli.invest.controller;

import com.fuli.invest.common.ApiResponse;
import com.fuli.invest.common.CurrentUserProvider;
import com.fuli.invest.entity.Tag;
import com.fuli.invest.repository.TagRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/** 供"记一笔交易"表单的标签选择/自动补全使用。 */
@RestController
@RequestMapping("/api/tags")
@RequiredArgsConstructor
public class TagController {

    private final TagRepository tagRepository;
    private final CurrentUserProvider currentUserProvider;

    @GetMapping
    public ApiResponse<List<String>> list() {
        Long userId = currentUserProvider.currentUserId();
        return ApiResponse.ok(tagRepository.findByUserIdOrderByNameAsc(userId).stream().map(Tag::getName).toList());
    }
}
