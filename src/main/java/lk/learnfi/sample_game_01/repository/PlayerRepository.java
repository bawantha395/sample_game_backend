package lk.learnfi.sample_game_01.repository;


import lk.learnfi.sample_game_01.entity.Player;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;


import java.util.Optional;

/**
 * @author Navishka Darshana - navishkada@gmail.com
 * @project simple-game-backend
 * @CreatedBy IntelliJ IDEA
 * @created 11/02/2024 - 11.57
 */
@Repository
public interface PlayerRepository extends JpaRepository<Player, Long> {

    Optional<Player> findFirstByUserName(String userName);

    Optional<Player> findFirstByEmail(String email);

    Optional<Player> findFirstByIdAndEmail(Long id,String email);
}
