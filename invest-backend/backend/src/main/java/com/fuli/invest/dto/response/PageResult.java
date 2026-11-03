package com.fuli.invest.dto.response;

import lombok.AllArgsConstructor;
import lombok.Getter;
import org.springframework.data.domain.Page;

import java.util.List;

@Getter
@AllArgsConstructor
public class PageResult<T> {
    private List<T> records;
    private long total;
    private int page;   // 0-based，和前端约定一致
    private int size;
    private boolean hasMore;

    public static <T> PageResult<T> of(Page<T> page) {
        return new PageResult<>(
                page.getContent(),
                page.getTotalElements(),
                page.getNumber(),
                page.getSize(),
                page.hasNext()
        );
    }
}
