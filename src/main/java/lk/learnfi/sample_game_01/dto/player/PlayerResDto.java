package lk.learnfi.sample_game_01.dto.player;

import lk.learnfi.sample_game_01.enums.common.AccountVerifyStatus;
import lk.learnfi.sample_game_01.enums.common.ActiveStatus;
import lk.learnfi.sample_game_01.enums.common.Level;
import lombok.*;
import lombok.experimental.SuperBuilder;

import java.util.Date;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@ToString
@SuperBuilder
public class PlayerResDto {
    private String id;
    private String userName;
    private String password;
    private String email;
    private AccountVerifyStatus email_verified;
    private double level;
    private Level level_eum;
    private Date created;
    private Date updated;
    private ActiveStatus status;
}
