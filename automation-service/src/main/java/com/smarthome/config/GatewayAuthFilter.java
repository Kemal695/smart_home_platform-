package com.smarthome.config;

import com.smarthome.auth.AuthenticatedUser;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.UUID;

@Component
public class GatewayAuthFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {

        var userId = request.getHeader("X-User-Id");
        if (userId != null && !userId.isEmpty()) {
            var homeId = request.getHeader("X-Home-Id");
            var userRole = request.getHeader("X-User-Role");
            var email = request.getHeader("X-User-Email");

            var user = new AuthenticatedUser(
                UUID.fromString(userId),
                homeId != null ? UUID.fromString(homeId) : null,
                email != null ? email : "",
                userRole != null ? userRole : ""
            );

            var auth = new UsernamePasswordAuthenticationToken(user, null, user.getAuthorities());
            SecurityContextHolder.getContext().setAuthentication(auth);
        }

        chain.doFilter(request, response);
    }
}
