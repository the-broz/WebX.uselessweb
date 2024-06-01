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
    }

    -- Function to handle button clicks
    local function handleClick(i, j)
        return function()
            if GAME_ACTIVE then
                if not board[i][j].hasBeenClicked then
                    board[i][j].hasBeenClicked = true
                    if FLAGS_LEFT > 0 then
                        boardGui[i][j].set_content(EMOJIS["flagged"])
                        FLAGS_LEFT = FLAGS_LEFT - 1
                    else
                        if board[i][j].isMine then
                            boardGui[i][j].set_content(EMOJIS["bomb_hit"])
                            GAME_ACTIVE = false
                            get("status").set_content("STATUS: YOU LOSE.")
                        else
                            boardGui[i][j].set_content(board[i][j].adjacentMines)
                        end
                    end
                else
                    FLAGS_LEFT = FLAGS_LEFT + 1
                    if board[i][j].isMine then
                        boardGui[i][j].set_content(EMOJIS["bomb_hit"])
                        GAME_ACTIVE = false
                        get("status").set_content("STATUS: YOU LOSE.")
                    else
                        boardGui[i][j].set_content(board[i][j].adjacentMines)
                    end
                end
            end
            get("flags_left").set_content(FLAGS_LEFT.." flags left.")
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
