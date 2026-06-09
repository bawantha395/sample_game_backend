package lk.learnfi.sample_game_01.dto.game;

import lk.learnfi.sample_game_01.enums.common.Level;
import lombok.*;

import java.util.Date;

/**
 * @author Navishka Darshana - navishkad@ceyentra.com
 * @project simple-game-backend
 * @CreatedBy IntelliJ IDEA
 * @created 14/04/2024 - 13.04
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@ToString
public class TopScoreResDto {
    private Long id;
    private String userName;
    private Level level_eum;
    private double point;
    private Date date;
}
