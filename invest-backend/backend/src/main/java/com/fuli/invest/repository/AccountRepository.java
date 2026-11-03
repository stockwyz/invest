package com.fuli.invest.repository;

import com.fuli.invest.entity.Account;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AccountRepository extends JpaRepository<Account, Long> {
    List<Account> findByUserIdOrderByCreatedAtAsc(Long userId);
}
