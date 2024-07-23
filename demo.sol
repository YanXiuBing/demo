// SPDX-License-Identifier: MIT  
pragma solidity ^0.8.0;  


interface IERC20 {  
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);  
    function transfer(address recipient, uint256 amount) external returns (bool);  
    function balanceOf(address account) external view returns (uint256);  
}  
contract USDTDeposit {  
    IERC20 public usdtToken; // USDT 代币合约地址  
    address public manager;   // 管理者地址  

    // 上级领导地址 
    mapping(address => address) public supervisors;   
    // 用于跟踪哪些地址已经设置了上级领导  
    mapping(address => bool) public hasSetSupervisor;  
    // 存储用户的存款，买一台算力就算存款多少。500U 可以得出1k算力
    mapping(address => uint256) public deposits;  
    // 存储每个上级领导的下属地址
    mapping(address => address[]) public subordinates;
    // 存储所有存款用户的地址
    address[] public depositors; 

    // 存储用户的存款，买一台硬件就算存款多少。1300U 可以得出1k算力
    mapping(address => uint256) public deposits4070;  
    // 存储所有存款用户的地址  
    address[] public depositors4070; 
    // 区代理
    mapping(address => address) public districtAgent;
    // 市代理
    mapping(address => address) public municipalAgent;  

    // 用户地址和等级的结构体  
    struct DepositorInfo {  
        address user;       // 用户地址  
        string level;      // 用户等级  
        uint256 deposit; // 存款
    } 

    // 构造函数，初始化 USDT 代币合约地址和管理者地址  
    constructor(address _usdtToken) {  
        usdtToken = IERC20(_usdtToken);  
        manager = msg.sender; // 部署合约的地址为管理者  
    }  

    // 存款函数，用户调用此函数将 USDT 存入合约  
    function deposit(uint256 amount) public {  
        require(amount == 500 * 10**18, "Amount must be 500 USDT"); // 要求金额必须等于 500 USDT
        address supervisor = supervisors[msg.sender];  // 获取上级领导
        // 计算上级的当前等级  
        string memory oldLevel = calculateLevel(supervisor); // 调用 calculateLevel 函数  
        // 调用 USDT 合约的 transferFrom 函数  
        // 用户需要先在 USDT 合约中授权合约地址持有一定数量的 USDT  
        require(usdtToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");  
        // 检查用户是否已经存款  
        if (deposits[msg.sender] == 0) {  
            depositors.push(msg.sender);  
        }  

        // 检查上级领导是否存在于 depositors 数组中，如果不在则添加  
        if (supervisor != address(0) && !isAddressInArray(supervisor, depositors)) {  
            depositors.push(supervisor); // 添加上级领导到存款者数组  
        }  

        // 更新用户存款  
        deposits[msg.sender] += amount;  

        // 给上级10%的奖励
        if (supervisor != address(0)) {  
        uint256 reward = (amount * 10) / 100; // 计算10%的奖励  

        // 计算升级奖励
        // 重新计算上级的等级  
        string memory newLevel = calculateLevel(supervisor); // 再次调用以获取新等级 
        uint256 additionalReward = 0;  
        if (keccak256(abi.encodePacked(newLevel)) != keccak256(abi.encodePacked(oldLevel))) {  
            if (keccak256(abi.encodePacked(newLevel)) == keccak256(abi.encodePacked("V1"))) {  
                additionalReward = 16 * 10**18; // v1 额外奖励  
            } else if (keccak256(abi.encodePacked(newLevel)) == keccak256(abi.encodePacked("V2"))) {  
                additionalReward = 14 * 10**18; // v2 额外奖励  
            } else if (keccak256(abi.encodePacked(newLevel)) == keccak256(abi.encodePacked("V3"))) {  
                additionalReward = 12 * 10**18; // v3 额外奖励  
            } else if (keccak256(abi.encodePacked(newLevel)) == keccak256(abi.encodePacked("V4"))) {  
                additionalReward = 10 * 10**18; // v4 额外奖励  
            } else if (keccak256(abi.encodePacked(newLevel)) == keccak256(abi.encodePacked("V5"))) {  
                additionalReward = 8 * 10**18;  // v5 额外奖励  
            }  
        }  
        // 总奖励  
        uint256 totalReward = reward + additionalReward;  

        // 转账操作  
        require(usdtToken.transfer(supervisor, totalReward), "Total reward transfer failed"); // 转账操作，注意处理小数位 
    }  
    }
    // 4070
    function deposit4070(uint256 amount) public {  
        require(amount == 1300 * 10**18, "Amount must be greater than 1300"); // 管理者要求金额大于 500  
        address supervisor = supervisors[msg.sender];  // 获取直接销售
        address indirect = supervisors[supervisor];  // 获取间接销售
        address _districtAgent = districtAgent[msg.sender];  // 获取区代理
        address _municipalAgent = municipalAgent[msg.sender];  // 获取市代理
        // 调用 USDT 合约的 transferFrom 函数  
        // 用户需要先在 USDT 合约中授权合约地址持有一定数量的 USDT  
        require(usdtToken.transferFrom(msg.sender, address(this), amount), "Transfer failed"); 
        // 检查用户是否已经存款  
        if (deposits4070[msg.sender] == 0) {  
            depositors4070.push(msg.sender);  
        }   
        // 更新用户存款  
        deposits4070[msg.sender] += amount;  

        // 给直接15%的奖励
        if (supervisor != address(0)){
        uint256 reward15 = (amount * 15) / 100; // 计算15%的奖励  
        // 转账操作  
        require(usdtToken.transfer(supervisor, reward15), "Direct sales transfer failed"); // 转账操作，注意处理小数位 
        }

        // 给间接5%的奖励
        uint256 reward5 = (amount * 5) / 100; // 计算5%的奖励  
        if (indirect != address(0)){
        // 转账操作  
        require(usdtToken.transfer(indirect, reward5), "Indirect sales transfer failed"); // 转账操作，注意处理小数位 
        }

        // 给区代理5%的奖励
        if (_districtAgent != address(0)){
        // 转账操作  
        require(usdtToken.transfer(_districtAgent, reward5), "Indirect sales transfer failed"); // 转账操作，注意处理小数位 
        }

        // 给市代理5%的奖励
        if (_municipalAgent != address(0)){
        // 转账操作  
        require(usdtToken.transfer(_municipalAgent, reward5), "Indirect sales transfer failed"); // 转账操作，注意处理小数位 
        }
    }  

    // 提款函数，只允许合约管理员调用  
    function withdraw(uint256 amount, address to) public {  
        require(msg.sender == manager, "Only manager can withdraw"); // 确保调用者是管理者  
        require(amount <= usdtToken.balanceOf(address(this)), "Insufficient balance in contract"); // 确保合约有足够的USDT  
        require(usdtToken.transfer(to, amount), "Transfer failed"); // 从合约转出USDT  
    }  

    // 批量转U
    function multiWithdraw(address[] memory recipients, uint256[] memory amounts) public {
        require(msg.sender == manager, "Only manager can withdraw");
        require(recipients.length == amounts.length, "Arrays length mismatch");

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            totalAmount += amounts[i];
        }

        require(totalAmount <= usdtToken.balanceOf(address(this)), "Insufficient balance in contract");

        for (uint256 i = 0; i < recipients.length; i++) {
            require(usdtToken.transfer(recipients[i], amounts[i]), "Transfer failed");
        }
    }

    // 获取用户存款的详细信息  
    function getDeposit(address user) public view returns (uint256) {  
        return deposits[user];  
    }  

    // 设置上级领导的函数，只能调用一次  
    function setSupervisor(address _supervisor) public {  
        require(!hasSetSupervisor[msg.sender], "You can only set supervisor once");  
        supervisors[msg.sender] = _supervisor; // 为每个用户设置上级领导
        hasSetSupervisor[msg.sender] = true; // 更新状态为已设置  

        // 添加归属领导归属
         subordinates[_supervisor].push(msg.sender);
    }  

    // 获取上级领导地址  
    function getSupervisor(address user) public view returns (address) {  
        return supervisors[user];  
    } 

    // 计算算力的函数  
    function calculatePower(address target) public view returns (uint256) {  
        // 获取该用户的下属地址  
        address[] memory subordinatesList = subordinates[target];  
        
        // 变量用于存储总存款  
        uint256 totalDeposit = 0;  
        uint256 maxDeposit = 0;  
        
        // 遍历下属地址  
        for (uint256 i = 0; i < subordinatesList.length; i++) {  
            address subordinate = subordinatesList[i];  
            uint256 depositAmount = deposits[subordinate];  

            // 累计总存款  
            totalDeposit += depositAmount;  

            // 查找最大存款  
            if (depositAmount > maxDeposit) {  
                maxDeposit = depositAmount;  
            }  
        }  

        // 去掉一个最大的值  
        totalDeposit -= maxDeposit;  

        // 除以 500  
        uint256 power = totalDeposit / (500* 10**18);  
        return power; // 返回最终的算力  
    }  

    // 计算等级V1-V5
    function calculateLevel(address target) public view returns (string memory) {  
        uint256 power = calculatePower(target);  

        if (power >= 1024) {  
            return "V5";  
        } else if (power >= 256) {  
            return "V4";  
        } else if (power >= 64) {  
            return "V3";  
        } else if (power >= 16) {  
            return "V2";  
        } else if (power >= 4) {  
            return "V1";  
        } else {  
            return "V0"; // 等级低于V1的情况  
        }  
    } 
    // 设置区代理
    function setDistrictAgent(address _user,address _districtAgent) public {  
        require(msg.sender == manager, "Only manager can withdraw"); // 确保调用者是管理者  
        districtAgent[_user] = _districtAgent; // 直接赋值  
    }  
    // 设置市代理
    function setMunicipalAgent(address _user,address _municipalAgent) public {  
        require(msg.sender == manager, "Only manager can withdraw"); // 确保调用者是管理者  
        municipalAgent[_user] = _municipalAgent; // 直接赋值  
    }  

    // 新增获取所有存款用户的函数  500
    function getAllDepositors() public view returns (DepositorInfo[] memory) {  
        DepositorInfo[] memory depositorsInfo = new DepositorInfo[](depositors.length); // 创建结构体数组  
        
        for (uint256 i = 0; i < depositors.length; i++) {  
            address user = depositors[i];  
            depositorsInfo[i] = DepositorInfo({user: user, level: calculateLevel(user),deposit: deposits[user]}); // 设置用户和等级  
        }  

        return depositorsInfo;  
    }  

    // 新增获取所有存款用户的函数  
    function getAllDepositors4070() public view returns (address[] memory) {  
        return depositors4070;  
    }  

    // 辅助函数：检查地址是否在数组中  
    function isAddressInArray(address addr, address[] memory array) private pure returns (bool) {  
        for (uint256 i = 0; i < array.length; i++) {  
            if (array[i] == addr) {  
            return true;  
            }  
        }  
        return false;  
    }  
}
