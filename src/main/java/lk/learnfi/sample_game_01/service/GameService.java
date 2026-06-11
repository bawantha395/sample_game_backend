package lk.learnfi.sample_game_01.service;

import lk.learnfi.sample_game_01.dto.game.*;

import java.util.List;

/**
 * @author Navishka Darshana - navishkada@gmail.com
 * @project simple-game-backend
 * @CreatedBy IntelliJ IDEA
 * @created 15/02/2024 - 10.09
 */
public interface GameService {
    GameDetailsResDto startGame(Long player_id);
    GameEndResDto endGame(Long player_id, GameEndReqDto gameEndType);
    GameAnswerCheckResDto checkAnswer(Long player_id, GameAnswerCheckReqDto gameAnswerCheckReqDto);
    List<TopScoreResDto> getTopScore();
}
