pragma solidity ^0.4.20;
pragma experimental ABIEncoderV2;

contract DXL {
    /*uint time;
    function getDate() internal returns(uint){
        time = now;
        return(time);
    }
    
    function callTime() public returns(uint){
        uint tim = getDate();
        return(tim);
    }
    获取当前时间的函数*/

    struct RM_Record{
        uint TransactionID;/*交易ID*/
        uint Money;/*捐款数额*/
        uint UserID;/*用户ID*/
        uint EventID;/*活动ID*/
        bytes32 RM_time;/*捐款时间*/

    }
    /*定义收款记录结构类型*/

    struct SM_Record{
        uint Money;
        uint EventID;
        bytes32 SM_time;
        uint TransactionID;
        bytes32 ProvidenceHash;
        bytes32 UPHash_Time;
    }
    /*定义资金使用记录类型*/

    RM_Record[1000] rm_records; 
    SM_Record[1000] sm_records;

    uint bottom_of_rm_records = 0;
    uint top_of_rm_records = 0;
    /*定义收款记录栈的栈底与栈顶*/

    uint bottom_of_sm_records = 0;
    uint top_of_sm_records = 0;
    /*定义资金使用记录栈的栈底与栈顶*/

    modifier OnlyEventInRM_Records(uint _EventID) {
        bool In_rm_records = false;
        for (uint i = bottom_of_rm_records; i < top_of_rm_records; i++){
            if (rm_records[i].EventID == _EventID){
                In_rm_records = true;
                break;
            }
        }
        require(In_rm_records, "该活动还未开始募集资金");
        _;
    }

    modifier OnlyEventInSM_Records(uint _EventID) {
        bool In_sm_records = false;
        for (uint i = bottom_of_sm_records; i < top_of_sm_records; i++) {
            if (sm_records[i].EventID == _EventID){
                In_sm_records = true;
                break;
            }
        }
        require(In_sm_records, "资金使用记录中不存在目标活动的资金使用情况记录");
        _;
    }

    modifier Verify_Money_Enough(uint _EventID, uint _Money) {
        uint sum_of_rm = Sum_of_money_in_RM(_EventID);
        uint sum_of_sm = Sum_of_money_in_SM(_EventID);
        require((sum_of_rm - sum_of_sm) >= _Money, "该活动筹集的善款不足以支持使用");
        _;
    }

    /*以下两个函数的入口参数均为后端传入*/
    function ReceiveMoney(uint _UserID, uint _Money, uint _EventID, bytes32 _Time) public returns(uint , uint , uint , bytes32) {
        bytes32 local_time;
        rm_records[top_of_rm_records].UserID = _UserID;
        rm_records[top_of_rm_records].Money = _Money;
        rm_records[top_of_rm_records].EventID = _EventID;
        local_time = _Time;
        rm_records[top_of_rm_records].RM_time = local_time;
        top_of_rm_records += 1;
        return(_UserID, _Money, _EventID, local_time);
    }

    /*函数收款存证：
    入口参数：
    1.用户地址 uint;
    2.收款金额 uint；
    3.活动地址 uint;
    返回值：
    1.用户ID uint；
    2.捐款数额 uint；
    3.活动ID uint；
    4.捐款时间 uint；
    */


    function QueryReceiveMoney (uint _EventID, uint _UserID) public OnlyEventInRM_Records(_EventID)returns(uint[], bytes32[], uint){
        uint[] memory rm_moneys = new uint[](100);
        bytes32[] memory rm_times = new bytes32[](100);
        uint rm_num = 0;
        for(uint i = bottom_of_rm_records;i < top_of_rm_records; i++) {
            if ((rm_records[i].UserID == _UserID) && (rm_records[i].EventID == _EventID)) {
                rm_moneys[rm_num] = rm_records[i].Money;
                rm_times[rm_num] = rm_records[i].RM_time;
                rm_num += 1;
            }
        }
         
        require( rm_num != 0, "该用户未给该活动捐款");
        return (rm_moneys, rm_times, rm_num);
    }
    /*函数资金收款记录查询
    入口参数：
    1.用户ID： uint;
    2.活动ID： uint;
    返回值：
    1.捐款数额 uint
    2.捐款时间 uint
    3.捐款次数 uint
    */

    function Sum_of_money_in_RM (uint _EventID) public OnlyEventInRM_Records(_EventID) returns (uint) {
        uint sum = 0;
        for (uint i = bottom_of_rm_records; i < top_of_rm_records; i++) {
            if (rm_records[i].EventID == _EventID) {
                sum += rm_records[i].Money;
            }
        }
        return sum;
    }
    /*函数活动收取捐款总额
    入口参数：
    1.活动ID uint；
    返回值：
    1.活动募集总资金
    */


    function SpendMoney(uint _Money, uint _EventID, uint _TransactionID, bytes32 _Time) public OnlyEventInRM_Records(_EventID) Verify_Money_Enough(_EventID,_Money) returns(uint ,uint , bytes32, uint){
        sm_records[top_of_sm_records].Money = _Money;
        sm_records[top_of_sm_records].EventID = _EventID;
        sm_records[top_of_sm_records].TransactionID = _TransactionID;
        sm_records[top_of_sm_records].SM_time = _Time;
        top_of_sm_records += 1;
        return (_EventID, _Money, _Time, _TransactionID);
    }
    /*函数资金使用情况存证：
    入口参数：
    1.使用资金地址：uint；
    2.活动地址：uint；
    返回值：
    1.活动ID uint;
    2.活动单次使用资金数额 uint；
    3.活动使用资金时间 uint;
    4.活动单次使用资金的交易ID uint；
    */

    function UploadProvidence (bytes32 _ProvidenceHash, uint _EventID, uint _TransactionID, bytes32 _Time) public OnlyEventInSM_Records(_EventID) returns(string){
        for(uint i = bottom_of_sm_records; i < top_of_sm_records; i++){
            if ((sm_records[i].EventID == _EventID) && (sm_records[i].TransactionID == _TransactionID)){
                sm_records[i].ProvidenceHash = _ProvidenceHash;
                sm_records[i].UPHash_Time = _Time;
                break;
            }
        }
        return("上传证据文件hash成功");
    }

    function QuerySpendMoney (uint _EventID) public OnlyEventInSM_Records(_EventID) returns (uint[], bytes32[], uint, bytes32[]){
        uint[] memory sm_moneys = new uint[](100);
        bytes32[] memory sm_times = new bytes32[](100);
        bytes32[] memory providencehashes = new bytes32[](100);
        uint sm_num = 0;

        for(uint i = bottom_of_sm_records; i < top_of_sm_records; i++) {
            if (sm_records[i].EventID == _EventID) {
                sm_moneys[sm_num] = sm_records[i].Money;
                sm_times[sm_num] = sm_records[i].SM_time;
                providencehashes[sm_num] = sm_records[i].ProvidenceHash;
                sm_num += 1;
            }
        }
        require(sm_num != 0, "该活动还未使用资金");
        return (sm_moneys, sm_times, sm_num, providencehashes);
    }
    /*函数资金使用记录查询
    入口参数：
    1.活动地址： uint256;
    返回值：
    1.活动使用资金数额 uint；
    2.活动使用资金时间 uint;
    3.活动使用资金次数 uint；
    4.活动使用资金的凭证文件hash bytes32；
    */

    function Sum_of_money_in_SM (uint _EventID) public OnlyEventInSM_Records(_EventID) returns (uint) {
        uint sum = 0;
        for (uint i = bottom_of_sm_records; i < top_of_sm_records; i++) {
            if (sm_records[i].EventID == _EventID) {
                sum += sm_records[i].Money;
            }
        }
        return sum;
    }
    /*函数资金使用总额
    入口参数：
    1.活动ID uint；
    返回值：
    1.活动使用的总资金
    */
}




