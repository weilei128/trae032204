package com.shop.service;

import com.shop.entity.User;
import com.shop.util.CsvUtil;
import org.springframework.stereotype.Service;

import javax.servlet.http.HttpSession;

@Service
public class UserService {

    private final CsvUtil csvUtil;

    public UserService(CsvUtil csvUtil) {
        this.csvUtil = csvUtil;
    }

    public User login(String username, String password) {
        User user = csvUtil.findUserByUsername(username);
        if (user != null && user.getPassword().equals(password)) {
            return user;
        }
        return null;
    }

    public void register(String username, String password) {
        if (csvUtil.findUserByUsername(username) != null) {
            throw new RuntimeException("用户名已存在");
        }
        User user = new User();
        user.setUsername(username);
        user.setPassword(password);
        user.setRole(0); // 普通用户
        csvUtil.addUser(user);
    }

    public User getCurrentUser(HttpSession session) {
        return (User) session.getAttribute("user");
    }

    public boolean isAdmin(HttpSession session) {
        User user = getCurrentUser(session);
        return user != null && user.getRole() == 1;
    }

    public void logout(HttpSession session) {
        session.invalidate();
    }
}
