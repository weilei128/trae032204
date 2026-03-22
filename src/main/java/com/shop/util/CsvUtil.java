package com.shop.util;

import com.opencsv.CSVReader;
import com.opencsv.CSVWriter;
import com.opencsv.exceptions.CsvException;
import com.shop.config.DataConfig;
import com.shop.entity.Order;
import com.shop.entity.Product;
import com.shop.entity.User;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import javax.annotation.PostConstruct;
import java.io.*;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicLong;

@Slf4j
@Component
public class CsvUtil {

    private final DataConfig dataConfig;
    private File dataDir;
    private File usersFile;
    private File productsFile;
    private File ordersFile;
    
    private AtomicLong userIdGenerator;
    private AtomicLong productIdGenerator;
    private AtomicLong orderIdGenerator;

    public CsvUtil(DataConfig dataConfig) {
        this.dataConfig = dataConfig;
    }

    @PostConstruct
    public void init() {
        // 创建数据目录
        dataDir = new File(dataConfig.getPath());
        if (!dataDir.exists()) {
            dataDir.mkdirs();
        }
        
        usersFile = new File(dataDir, dataConfig.getUsersFile());
        productsFile = new File(dataDir, dataConfig.getProductsFile());
        ordersFile = new File(dataDir, dataConfig.getOrdersFile());
        
        // 初始化文件
        initUsersFile();
        initProductsFile();
        initOrdersFile();
        
        // 初始化ID生成器
        userIdGenerator = new AtomicLong(getMaxUserId());
        productIdGenerator = new AtomicLong(getMaxProductId());
        orderIdGenerator = new AtomicLong(getMaxOrderId());
    }

    private void initUsersFile() {
        if (!usersFile.exists()) {
            try (CSVWriter writer = new CSVWriter(new OutputStreamWriter(new FileOutputStream(usersFile), StandardCharsets.UTF_8))) {
                // 写入表头
                writer.writeNext(new String[]{"id", "username", "password", "role"});
                // 写入默认管理员
                writer.writeNext(new String[]{"1", "admin", "admin", "1"});
                log.info("创建用户数据文件: {}", usersFile.getAbsolutePath());
            } catch (IOException e) {
                log.error("创建用户数据文件失败", e);
            }
        }
    }

    private void initProductsFile() {
        if (!productsFile.exists()) {
            try (CSVWriter writer = new CSVWriter(new OutputStreamWriter(new FileOutputStream(productsFile), StandardCharsets.UTF_8))) {
                // 写入表头
                writer.writeNext(new String[]{"id", "name", "description", "price", "stock"});
                // 写入示例商品
                writer.writeNext(new String[]{"1", "苹果手机", "iPhone 15 Pro", "7999.00", "100"});
                writer.writeNext(new String[]{"2", "华为手机", "Mate 60 Pro", "6999.00", "80"});
                writer.writeNext(new String[]{"3", "小米耳机", "无线蓝牙耳机", "299.00", "200"});
                writer.writeNext(new String[]{"4", "机械键盘", "Cherry轴机械键盘", "599.00", "50"});
                writer.writeNext(new String[]{"5", "鼠标", "无线游戏鼠标", "199.00", "150"});
                log.info("创建商品数据文件: {}", productsFile.getAbsolutePath());
            } catch (IOException e) {
                log.error("创建商品数据文件失败", e);
            }
        }
    }

    private void initOrdersFile() {
        if (!ordersFile.exists()) {
            try (CSVWriter writer = new CSVWriter(new OutputStreamWriter(new FileOutputStream(ordersFile), StandardCharsets.UTF_8))) {
                // 写入表头
                writer.writeNext(new String[]{"id", "userId", "username", "productId", "productName", "quantity", "totalPrice", "createTime"});
                log.info("创建订单数据文件: {}", ordersFile.getAbsolutePath());
            } catch (IOException e) {
                log.error("创建订单数据文件失败", e);
            }
        }
    }

    // ==================== 用户操作 ====================
    
    public List<User> readAllUsers() {
        List<User> users = new ArrayList<>();
        try (CSVReader reader = new CSVReader(new InputStreamReader(new FileInputStream(usersFile), StandardCharsets.UTF_8))) {
            List<String[]> lines = reader.readAll();
            // 跳过表头
            for (int i = 1; i < lines.size(); i++) {
                String[] line = lines.get(i);
                if (line.length >= 4) {
                    User user = new User();
                    user.setId(Long.parseLong(line[0]));
                    user.setUsername(line[1]);
                    user.setPassword(line[2]);
                    user.setRole(Integer.parseInt(line[3]));
                    users.add(user);
                }
            }
        } catch (IOException | CsvException e) {
            log.error("读取用户数据失败", e);
        }
        return users;
    }

    public User findUserByUsername(String username) {
        return readAllUsers().stream()
                .filter(u -> u.getUsername().equals(username))
                .findFirst()
                .orElse(null);
    }

    public User findUserById(Long id) {
        return readAllUsers().stream()
                .filter(u -> u.getId().equals(id))
                .findFirst()
                .orElse(null);
    }

    public void addUser(User user) {
        user.setId(userIdGenerator.incrementAndGet());
        try (CSVWriter writer = new CSVWriter(new OutputStreamWriter(new FileOutputStream(usersFile, true), StandardCharsets.UTF_8))) {
            writer.writeNext(new String[]{
                    String.valueOf(user.getId()),
                    user.getUsername(),
                    user.getPassword(),
                    String.valueOf(user.getRole())
            });
        } catch (IOException e) {
            log.error("添加用户失败", e);
        }
    }

    private long getMaxUserId() {
        return readAllUsers().stream()
                .mapToLong(User::getId)
                .max()
                .orElse(0L);
    }

    // ==================== 商品操作 ====================
    
    public List<Product> readAllProducts() {
        List<Product> products = new ArrayList<>();
        try (CSVReader reader = new CSVReader(new InputStreamReader(new FileInputStream(productsFile), StandardCharsets.UTF_8))) {
            List<String[]> lines = reader.readAll();
            // 跳过表头
            for (int i = 1; i < lines.size(); i++) {
                String[] line = lines.get(i);
                if (line.length >= 5) {
                    Product product = new Product();
                    product.setId(Long.parseLong(line[0]));
                    product.setName(line[1]);
                    product.setDescription(line[2]);
                    product.setPrice(new BigDecimal(line[3]));
                    product.setStock(Integer.parseInt(line[4]));
                    products.add(product);
                }
            }
        } catch (IOException | CsvException e) {
            log.error("读取商品数据失败", e);
        }
        return products;
    }

    public Product findProductById(Long id) {
        return readAllProducts().stream()
                .filter(p -> p.getId().equals(id))
                .findFirst()
                .orElse(null);
    }

    public void addProduct(Product product) {
        product.setId(productIdGenerator.incrementAndGet());
        try (CSVWriter writer = new CSVWriter(new OutputStreamWriter(new FileOutputStream(productsFile, true), StandardCharsets.UTF_8))) {
            writer.writeNext(new String[]{
                    String.valueOf(product.getId()),
                    product.getName(),
                    product.getDescription(),
                    product.getPrice().toString(),
                    String.valueOf(product.getStock())
            });
        } catch (IOException e) {
            log.error("添加商品失败", e);
        }
    }

    public void updateProduct(Product product) {
        List<Product> products = readAllProducts();
        for (int i = 0; i < products.size(); i++) {
            if (products.get(i).getId().equals(product.getId())) {
                products.set(i, product);
                break;
            }
        }
        writeAllProducts(products);
    }

    public void deleteProduct(Long id) {
        List<Product> products = readAllProducts();
        products.removeIf(p -> p.getId().equals(id));
        writeAllProducts(products);
    }

    private void writeAllProducts(List<Product> products) {
        try (CSVWriter writer = new CSVWriter(new OutputStreamWriter(new FileOutputStream(productsFile), StandardCharsets.UTF_8))) {
            writer.writeNext(new String[]{"id", "name", "description", "price", "stock"});
            for (Product product : products) {
                writer.writeNext(new String[]{
                        String.valueOf(product.getId()),
                        product.getName(),
                        product.getDescription(),
                        product.getPrice().toString(),
                        String.valueOf(product.getStock())
                });
            }
        } catch (IOException e) {
            log.error("写入商品数据失败", e);
        }
    }

    private long getMaxProductId() {
        return readAllProducts().stream()
                .mapToLong(Product::getId)
                .max()
                .orElse(0L);
    }

    // ==================== 订单操作 ====================
    
    public List<Order> readAllOrders() {
        List<Order> orders = new ArrayList<>();
        try (CSVReader reader = new CSVReader(new InputStreamReader(new FileInputStream(ordersFile), StandardCharsets.UTF_8))) {
            List<String[]> lines = reader.readAll();
            // 跳过表头
            for (int i = 1; i < lines.size(); i++) {
                String[] line = lines.get(i);
                if (line.length >= 8) {
                    Order order = new Order();
                    order.setId(Long.parseLong(line[0]));
                    order.setUserId(Long.parseLong(line[1]));
                    order.setUsername(line[2]);
                    order.setProductId(Long.parseLong(line[3]));
                    order.setProductName(line[4]);
                    order.setQuantity(Integer.parseInt(line[5]));
                    order.setTotalPrice(new BigDecimal(line[6]));
                    order.setCreateTime(LocalDateTime.parse(line[7], DateTimeFormatter.ISO_LOCAL_DATE_TIME));
                    orders.add(order);
                }
            }
        } catch (IOException | CsvException e) {
            log.error("读取订单数据失败", e);
        }
        return orders;
    }

    public List<Order> findOrdersByUserId(Long userId) {
        return readAllOrders().stream()
                .filter(o -> o.getUserId().equals(userId))
                .collect(java.util.stream.Collectors.toList());
    }

    public void addOrder(Order order) {
        order.setId(orderIdGenerator.incrementAndGet());
        order.setCreateTime(LocalDateTime.now());
        try (CSVWriter writer = new CSVWriter(new OutputStreamWriter(new FileOutputStream(ordersFile, true), StandardCharsets.UTF_8))) {
            writer.writeNext(new String[]{
                    String.valueOf(order.getId()),
                    String.valueOf(order.getUserId()),
                    order.getUsername(),
                    String.valueOf(order.getProductId()),
                    order.getProductName(),
                    String.valueOf(order.getQuantity()),
                    order.getTotalPrice().toString(),
                    order.getCreateTime().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME)
            });
        } catch (IOException e) {
            log.error("添加订单失败", e);
        }
    }

    private long getMaxOrderId() {
        return readAllOrders().stream()
                .mapToLong(Order::getId)
                .max()
                .orElse(0L);
    }
}
