# 简易小商城

基于 Spring Boot + H5 的简易商城系统，使用 CSV 文件存储数据。

## 功能特性

- 用户登录/注册（普通用户 + 管理员）
- 商品列表展示
- 用户下单购买
- 管理员商品管理（增删改查）
- 管理员查看所有订单
- CSV 文件数据持久化

## 技术栈

- Spring Boot 2.7.14
- Thymeleaf 模板引擎
- OpenCSV 处理 CSV 文件
- H5 响应式前端

## 默认账号

- 管理员：admin / admin
- 普通用户：可自行注册

## 运行方式

### 方式一：使用 Maven（推荐）

```bash
# 编译
mvn clean compile

# 运行
mvn spring-boot:run
```

### 方式二：使用 IDE

1. 使用 IntelliJ IDEA 或 Eclipse 导入项目
2. 运行 SimpleShopApplication 类

### 方式三：打包运行

```bash
# 打包
mvn clean package -DskipTests

# 运行
java -jar target/simple-shop-1.0.0.jar
```

## 访问地址

- 首页：http://localhost:8080
- 登录页：http://localhost:8080/login
- 商城：http://localhost:8080/shop
- 管理后台：http://localhost:8080/admin

## 数据文件

数据存储在项目目录下的 `data` 文件夹中：
- `users.csv` - 用户数据
- `products.csv` - 商品数据
- `orders.csv` - 订单数据
