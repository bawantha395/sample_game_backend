package lk.learnfi.sample_game_01.service;

import lk.learnfi.sample_game_01.dto.player.PlayerReqDto;

/**
 * @author Navishka Darshana - navishkada@gmail.com
 * @project simple-game-backend
 * @CreatedBy IntelliJ IDEA
 * @created 15/02/2024 - 08.50
 */
public interface PlayerService {
    void saveNewPlayer(PlayerReqDto playerReqDto);

    void verifyAccountAndEmail(String token);

}
