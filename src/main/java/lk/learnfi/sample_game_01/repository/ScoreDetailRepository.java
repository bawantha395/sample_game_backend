package lk.learnfi.sample_game_01.repository;

import lk.learnfi.sample_game_01.entity.ScoreDetail;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ScoreDetailRepository extends JpaRepository<ScoreDetail, Long> {
}
