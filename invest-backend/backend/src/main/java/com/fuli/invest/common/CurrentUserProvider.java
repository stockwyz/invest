package com.fuli.invest.common;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * MVP 阶段占位：未接入登录鉴权，所有请求都当作同一个用户处理。
 * 接入 JWT 后，把 currentUserId() 换成从 SecurityContext / 请求头里解析出来的真实 userId，
 * Controller/Service 层不用改一行——都是通过这个类拿 userId。
 */
@Component
public class CurrentUserProvider {

    @Value("${app.default-user-id:1}")
    private Long defaultUserId;

    public Long currentUserId() {
        // TODO: 替换为 JWT 解析，例如：
        // Long uid = (Long) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        return defaultUserId;
    }
}
