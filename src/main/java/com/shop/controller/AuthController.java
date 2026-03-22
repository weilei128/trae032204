package com.shop.controller;

import com.shop.entity.User;
import com.shop.service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpSession;
import java.util.HashMap;
import java.util.Map;

@Controller
public class AuthController {

    private final UserService userService;

    public AuthController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/")
    public String index() {
        return "redirect:/login";
    }

    @GetMapping("/login")
    public String loginPage() {
        return "login";
    }

    @PostMapping("/api/login")
    @ResponseBody
    public ResponseEntity<?> login(@RequestParam String username, 
                                   @RequestParam String password,
                                   HttpSession session) {
        Map<String, Object> result = new HashMap<>();
        User user = userService.login(username, password);
        if (user != null) {
            session.setAttribute("user", user);
            result.put("success", true);
            result.put("role", user.getRole());
            result.put("message", "登录成功");
        } else {
            result.put("success", false);
            result.put("message", "用户名或密码错误");
        }
        return ResponseEntity.ok(result);
    }

    @PostMapping("/api/register")
    @ResponseBody
    public ResponseEntity<?> register(@RequestParam String username, 
                                      @RequestParam String password) {
        Map<String, Object> result = new HashMap<>();
        try {
            userService.register(username, password);
            result.put("success", true);
            result.put("message", "注册成功");
        } catch (Exception e) {
            result.put("success", false);
            result.put("message", e.getMessage());
        }
        return ResponseEntity.ok(result);
    }

    @GetMapping("/api/logout")
    @ResponseBody
    public ResponseEntity<?> logout(HttpSession session) {
        userService.logout(session);
        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("message", "退出成功");
        return ResponseEntity.ok(result);
    }

    @GetMapping("/api/current-user")
    @ResponseBody
    public ResponseEntity<?> getCurrentUser(HttpSession session) {
        User user = userService.getCurrentUser(session);
        if (user != null) {
            return ResponseEntity.ok(user);
        }
        return ResponseEntity.ok(null);
    }
}
