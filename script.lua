function initializeGame(rows, cols, numMines)
    local board = {}
    local FLAGS_LEFT = numMines
    local GAME_ACTIVE = true
    get("status").set_content("STATUS: GAME STARTED.")
    get("flags_left").set_content(numMines .. " flags left.")
    
    local function initializeBoard()
        for i = 1, rows do
            board[i] = {}
            for j = 1, cols do
                board[i][j] = {
                    isMine = false,
                    hasBeenClicked = false,
                    isRevealed = false,
                    flagged = false,
                    adjacentMines = 0
                }
            end
        end
    end

    local function placeMines()
        local minesPlaced = 0
        while minesPlaced < numMines do
            local row = math.random(1, rows)
            local col = math.random(1, cols)
            if not board[row][col].isMine then
                board[row][col].isMine = true
                minesPlaced = minesPlaced + 1
            end
        end
    end

    local function countAdjacentMines()
        for i = 1, rows do
            for j = 1, cols do
                local count = 0
                for x = -1, 1 do
                    for y = -1, 1 do
                        local newRow = i + x
                        local newCol = j + y
                        if newRow >= 1 and newRow <= rows and newCol >= 1 and newCol <= cols then
                            if board[newRow][newCol].isMine then
                                count = count + 1
                            end
                        end
                    end
                end
                board[i][j].adjacentMines = count
            end
        end
    end

    initializeBoard()
    placeMines()
    countAdjacentMines()

    local boardGui = {}
    for i = 1, rows do
        boardGui[i] = {}
        for j = 1, cols do
            boardGui[i][j] = get("x"..i.."y"..j)
            boardGui[i][j].set_content("?")
        end
    end

    local EMOJIS = {
        ["bomb_hit"] = "💥",
        ["flagged"] = "🚩",
        ["misplace"] = "❌"
    }

    local function revealBoard()
        for i, row in ipairs(boardGui) do
            for j, cell in ipairs(row) do
                if board[i][j].isMine then
                    cell.set_content(EMOJIS["bomb_hit"])
                else
                    cell.set_content(board[i][j].adjacentMines)
                end
            end
        end
    end
    
    local function checkMisplacedFlags()
        for i, row in ipairs(boardGui) do
            for j, cell in ipairs(row) do
                if board[i][j].flagged and not board[i][j].isMine then
                    cell.set_content(EMOJIS["misplace"])
                end
            end
        end
    end
    
    local function endGame()
        GAME_ACTIVE = false
        revealBoard()
        checkMisplacedFlags()
    end

    local function revealAdjacentZeros(row, col)
        if row < 1 or row > #board or col < 1 or col > #board[1] then
            return
        end
        if board[row][col].isRevealed or board[row][col].isMine or board[row][col].flagged then
            return
        end
        boardGui[row][col].set_content(board[row][col].adjacentMines)
        board[row][col].isRevealed = true
        if board[row][col].adjacentMines == 0 then
            for x = -1, 1 do
                for y = -1, 1 do
                    revealAdjacentZeros(row + x, col + y)
                end
            end
        end
    end

    local function checkWin()
        local totalNonMineCells = 0
        local revealedNonMineCells = 0
        for i, row in ipairs(board) do
            for j, cell in ipairs(row) do
                if not cell.isMine then
                    totalNonMineCells = totalNonMineCells + 1
                    if cell.isRevealed then
                        revealedNonMineCells = revealedNonMineCells + 1
                    end
                end
            end
        end
        return totalNonMineCells == revealedNonMineCells
    end

    local function handleClick(i, j)
        return function()
            if GAME_ACTIVE then
                if not board[i][j].hasBeenClicked then
                    if FLAGS_LEFT > 0 then
                        if not board[i][j].flagged then
                            boardGui[i][j].set_content(EMOJIS["flagged"])
                            board[i][j].flagged = true
                            FLAGS_LEFT = FLAGS_LEFT - 1
                        end
                    else
                        if board[i][j].isMine then
                            boardGui[i][j].set_content(EMOJIS["bomb_hit"])
                            get("status").set_content("STATUS: YOU LOSE.")
                            endGame()
                        else
                            revealAdjacentZeros(i, j)
                        end
                    end
                elseif board[i][j].flagged then
                    boardGui[i][j].set_content("?")
                    board[i][j].flagged = false
                    FLAGS_LEFT = FLAGS_LEFT + 1
                else
                    if not board[i][j].isMine then
                        revealAdjacentZeros(i, j)
                    else
                        boardGui[i][j].set_content(EMOJIS["bomb_hit"])
                        get("status").set_content("STATUS: YOU LOSE.")
                        endGame()
                    end
                end
            end
            get("flags_left").set_content(FLAGS_LEFT.." flags left.")
            if checkWin() then
                GAME_ACTIVE = false
                get("status").set_content("STATUS: YOU WIN!")
            end
        end
    end

    for i, row in ipairs(boardGui) do
        for j, cell in ipairs(row) do
            cell.on_click(handleClick(i, j))
        end
    end
end

initializeGame(5, 5, 5)

function restartGame() 
    initializeGame(5, 5, 5) 
end

local restartButton = get("reset")
restartButton.on_click(restartGame)
