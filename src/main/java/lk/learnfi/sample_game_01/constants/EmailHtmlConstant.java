package lk.learnfi.sample_game_01.constants;


import lk.learnfi.sample_game_01.entity.Player;
import org.springframework.stereotype.Component;

@Component
public class EmailHtmlConstant {

    public static String getPlayerVerificationEmailBody(String url, Player player) {
        return "<p> "+"Hello "+ player.getUserName()+","+"</p> \n" +
                "<br/>"+
                "<p>"+"verification link - "+ url+ "</p>";
    }
}
