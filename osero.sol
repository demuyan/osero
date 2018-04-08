pragma solidity ^0.4.19;

contract BaseContract {
    enum StoneColor {None, Black, White }
}

// ゲームとして管理する
contract OseroMain is BaseContract
{
    Board board;
    address owner;    // 自分
    address opponent; // 対戦相手

    // コンストラクタ
    function OseroMain() public {
        owner = msg.sender;
    }

    // 対戦開始
    function start(address _opponent) public {

        opponent = _opponent;
        board = new Board();
        board.init();
    }

    // ゲームが終了した？
    function isGameOver() public view returns (bool flg, StoneColor winner){
        (flg, winner) = board.isGameOver();
    }

    // 石を置く
    function putStone(uint x, uint y, address _addr) public returns (uint success){

        require((_addr==owner)||(_addr==opponent));  // ----- (1)
        require(0 <= x && x <= 8);
        require(0 <= y && y <= 8);

        StoneColor col = StoneColor.Black;
        if (_addr == opponent){
            col = StoneColor.White;
        }

        success = board.putStone(x,y, col);          // ----- (2)
    }

}

// オセロ版盤の管理
contract Board is BaseContract{

    // オセロ盤の情報
    StoneColor[8][8] board;

    // コンストラクタ
    function Board() public {
        init();
    }

    // 初期化
    function init() public {

        for (uint y = 0; y < 8; y++){
            for (uint x = 0; x < 8; x++){
                board[y][x] = StoneColor.None;
            }
        }
        board[3][3] = board[4][4] = StoneColor.White;
        board[4][3] = board[3][4] = StoneColor.Black;
    }

    // 石が置けるか確認する
    function checkPutable(uint x, uint y, StoneColor col, int dirX, int dirY, uint stones)
      public view returns (uint reverseStones) {

        int xx = int(x) + dirX;
        int yy = int(y) + dirY;

        reverseStones = stones;

        if (xx <  0 || 7 < xx || yy <  0 || 7 < yy){
            reverseStones = 0;
            return;
        }

        StoneColor stoneCol = board[uint(yy)][uint(xx)];
        if (stoneCol == StoneColor.None){
            reverseStones = 0;
            return;
        }

        if (stoneCol != col){
            return;
        }

        stones++;

        reverseStones = checkPutable(uint(xx),uint(yy),col,dirX,dirY,stones);
        return reverseStones;
    }

    // 石の色をもう一方の色に変える
    function reverseColor(StoneColor col) private pure returns(StoneColor retcol) {
        retcol = StoneColor.Black;
        if (col == StoneColor.Black){
            retcol = StoneColor.White;
        }
    }

    // 石をひっくりかえす
    function reverseStones(uint x, uint y,StoneColor col, int dirX, int dirY,uint count)
      public {

        int xx = int(x) + dirX;
        int yy = int(y) + dirY;

        for (uint i = 0 ; i < count; i++){
            board[uint(yy)][uint(xx)] = col;
            xx += dirX;
            yy += dirY;
        }
    }

    // ひっくり返せる石があればひっくりかえす
    function checkAndReverse(uint x, uint y,StoneColor col, int dirX, int dirY)
      public returns (uint count){

        count = checkPutable(x,y,col, dirX, dirY, 0);
        if(0 < count){
            reverseStones(x,y,reverseColor(col),dirX,dirY,count);
        }

    }

    // 石を盤に置く
    function putStone(uint x, uint y, StoneColor col) public returns (uint count){

        require(0 <= x && x <= 7);
        require(0 <= y && y <= 7);
        require(col == StoneColor.Black || col == StoneColor.White);

        count = 0;
        count += checkAndReverse(x,y,reverseColor(col), -1, -1); // ----- (3)
        count += checkAndReverse(x,y,reverseColor(col), -1,  0);
        count += checkAndReverse(x,y,reverseColor(col), -1,  1);
        count += checkAndReverse(x,y,reverseColor(col),  0, -1);
        count += checkAndReverse(x,y,reverseColor(col),  0,  1);
        count += checkAndReverse(x,y,reverseColor(col),  1, -1);
        count += checkAndReverse(x,y,reverseColor(col),  1,  0);
        count += checkAndReverse(x,y,reverseColor(col),  1,  1);
        if (0 < count){
            board[y][x] = col;
        }
    }

    // ゲームが終了したかを確認する
    function isGameOver() public view returns(bool gameOver, StoneColor winner){

        gameOver = false;

        // 石を数える
        uint blackStone = 0;
        uint whiteStone = 0;
        for (uint y =0; y < 7; y++){
            for (uint x = 0; x < 7; x++){
                if (board[y][x] == StoneColor.None){
                    return;
                }
                if (board[y][x] == StoneColor.Black){
                    blackStone++;
                }
                if (board[y][x] == StoneColor.White){
                    whiteStone++;
                }
            }
        }

        gameOver = true;
        // 勝者の判定
        winner = StoneColor.None;
        if (whiteStone == whiteStone){
            return;
        }

        winner = StoneColor.White;
        if (whiteStone < blackStone){
            winner = StoneColor.Black;
        }
    }
}
