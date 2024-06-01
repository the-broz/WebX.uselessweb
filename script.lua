-- Define the function to initialize the game
function initializeGame(rows, cols, numMines)
    local board = {}
    local FLAGS_LEFT = 5
local GAME_ACTIVE = true
get("status").set_content("STATUS: GAME STARTED.")
get("flags_left").set_content("5 flags left.")
    -- Function to initialize the board
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

    -- Function to randomly place mines on the board
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

    -- Function to count adjacent mines for each cell
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

    -- Initialize the board, place mines, and count adjacent mines
    initializeBoard()
    placeMines()
    countAdjacentMines()

    -- Setup the game GUI
    local boardGui = {}
    for i = 1, rows do
        boardGui[i] = {}
        for j = 1, cols do
            boardGui[i][j] = get("x"..i.."y"..j)
            boardGui[i][j].set_content("?")
        end
    end

    -- Define emojis for different states
    local EMOJIS = {
        ["bomb_hit"] = "💥",
        ["flagged"] = "🚩",
        ["misplace"]= "❌",
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
    
    -- Function to check for misplaced flags
    local function checkMisplacedFlags()
        for i, row in ipairs(boardGui) do
            for j, cell in ipairs(row) do
                if board[i][j].flagged and not board[i][j].isMine then
                    cell.set_content(EMOJIS["misplace"])  -- Set content to indicate misplaced flag
                end
            end
        end
    end

    local function checkWin()
        local totalNonMineCells = 0
        local revealedNonMineCells = 0
        for i, row in ipairs(boardGui) do
            for j, cell in ipairs(row) do
                if not board[i][j].isMine then
                    totalNonMineCells = totalNonMineCells + 1
                    if board[i][j].isRevealed then
                        revealedNonMineCells = revealedNonMineCells + 1
                    end
                end
            end
        end
        -- If all non-mine cells have been revealed, the user wins
        if totalNonMineCells == revealedNonMineCells then
            return true
        else
            return false
        end
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
    
    -- Function to handle game end
    local function endGame()
        GAME_ACTIVE = false
        revealBoard()
        checkMisplacedFlags()
    end

    -- Function to handle button clicks
    local function handleClick(i, j)
        return function()
            if GAME_ACTIVE then
                if not board[i][j].hasBeenClicked then
                    board[i][j].hasBeenClicked = true
                    if FLAGS_LEFT > 0 then
                        boardGui[i][j].set_content(EMOJIS["flagged"])
                        board[i][j].flagged = true
                        FLAGS_LEFT = FLAGS_LEFT - 1
                    else
                        board[i][j].flagged = false
                        if board[i][j].isMine then
                            boardGui[i][j].set_content(EMOJIS["bomb_hit"])
                            get("status").set_content("STATUS: YOU LOSE.")
                            endGame()
                        else
                            revealAdjacentZeros(i, j)
                        end
                    end
                else
                    FLAGS_LEFT = FLAGS_LEFT + 1
                    if board[i][j].isMine then
                        boardGui[i][j].set_content(EMOJIS["bomb_hit"])
                        board[i][j].flagged = false
                        get("status").set_content("STATUS: YOU LOSE.")
                        endGame()
                    else
                        revealAdjacentZeros(i, j)
                    end
                end
            end
            get("flags_left").set_content(FLAGS_LEFT.." flags left.")
            if checkWin() then
                GAME_ACTIVE = false
                get("status").set_content("STATUS: YOU WIN! 🎉🎉")  -- Indicate win when all non-mine cells are revealed
            end
        end
    end

    -- Assign click handlers to buttons
    for i, row in ipairs(boardGui) do
        for j, cell in ipairs(row) do
            cell.on_click(handleClick(i, j))
        end
    end
end

-- Initialize the game
initializeGame(5, 5, 5)

-- Function to restart the game
function restartGame()
    FLAGS_LEFT = 5
    GAME_ACTIVE = true
    initializeGame(5, 5, 5)
end

-- Example: Restart the game when a button is clicked
local restartButton = get("reset")
restartButton.on_click(restartGame)
