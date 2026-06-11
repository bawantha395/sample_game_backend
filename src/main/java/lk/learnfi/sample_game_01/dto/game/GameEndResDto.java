package lk.learnfi.sample_game_01.dto.game;

import lombok.*;

/**
 * @author Navishka Darshana - navishkada@gmail.com
 * @project simple-game-backend
 * @CreatedBy IntelliJ IDEA
 * @created 12/03/2024 - 11.10
 */

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@ToString
public class GameEndResDto {
    private Long score_id;
    private double total_point;
}
