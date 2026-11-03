package com.fuli.invest.repository;

import com.fuli.invest.entity.Tag;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface TagRepository extends JpaRepository<Tag, Long> {
    List<Tag> findByUserIdOrderByNameAsc(Long userId);
    Optional<Tag> findByUserIdAndName(Long userId, String name);
}
