package lk.learnfi.sample_game_01.config.security.custom;


import lk.learnfi.sample_game_01.dto.auth.UserAuthDto;
import lk.learnfi.sample_game_01.service.authService.UserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.log4j.Log4j2;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.oauth2.common.DefaultOAuth2AccessToken;
import org.springframework.security.oauth2.common.OAuth2AccessToken;
import org.springframework.security.oauth2.provider.OAuth2Authentication;
import org.springframework.security.oauth2.provider.token.store.JwtAccessTokenConverter;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.util.HashMap;
import java.util.Map;




@Component
@Log4j2
@RequiredArgsConstructor
public class CustomTokenEnhancer extends JwtAccessTokenConverter {

    private final UserService userService;

    @Override
    public OAuth2AccessToken enhance(OAuth2AccessToken oAuth2AccessToken, OAuth2Authentication oAuth2Authentication) {
        final Map<String, Object> additionalInfo = new HashMap<>();


        UsernamePasswordAuthenticationToken authentication =
                (UsernamePasswordAuthenticationToken) SecurityContextHolder.getContext().getAuthentication();
        User user_ = (User) authentication.getPrincipal();
        String clientId = user_.getUsername();

        UserAuthDto user = (UserAuthDto) oAuth2Authentication.getPrincipal();

        additionalInfo.put("user", user);
        additionalInfo.put("domain", getServerDomain());

        ((DefaultOAuth2AccessToken) oAuth2AccessToken).setAdditionalInformation(additionalInfo);

        return super.enhance(oAuth2AccessToken, oAuth2Authentication);
    }

    public static String getServerDomain() {
        return ServletUriComponentsBuilder.fromCurrentContextPath().build().toUriString();
    }
}
