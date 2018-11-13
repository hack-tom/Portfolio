module DomsMatch where

 {- play a 5's & 3's singles match between 2 given players
    play n games, each game up to 61
 -}
  
 --import Doms
 import System.Random
 import Data.List
 import Debug.Trace
 import Data.Tuple
 
 type Dom = (Int,Int)
 -- with highest pip first i.e. (6,1) not (1,6)

 data DomBoard = InitBoard|Board Dom Dom History
                    deriving (Show)
 
 type History = [(Dom,Player,MoveNum)]
 -- History allows course of game to be reconstructed                                            
                                               
 data Player = P1|P2 -- player 1 or player 2
                  deriving (Eq,Show, Enum)
 
 data End = L|R -- left end or right end
                  deriving (Eq,Show)
 
 type MoveNum = Int

 type Hand = [Dom]
  
 -- the full set of Doms
 domSet :: [Dom] 
 
 domSet = [(6,6),(6,5),(6,4),(6,3),(6,2),(6,1),(6,0),
                 (5,5),(5,4),(5,3),(5,2),(5,1),(5,0),
                       (4,4),(4,3),(4,2),(4,1),(4,0),
                             (3,3),(3,2),(3,1),(3,0),
                                   (2,2),(2,1),(2,0),
                                         (1,1),(1,0),
                                               (0,0)]
                                                                                         
 
 type Move = (Dom,End)
 type Scores = (Int,Int)
                                                                                              
 -- state in a game - p1's hand, p2's hand, player to drop, current board, scores 
 type GameState =(Hand,Hand,Player, DomBoard, Scores)
 
 -- Critical Tactics - Return dominoes which either return a winning domino or stop a loss.
 type Tactic = DomBoard -> Player -> Hand -> Scores -> [PossMove]
 
 -----------------------------------------------------------------------------------------
 
 -- Helper Functions
 
 
 resMaybe :: Maybe a ->a
 resMaybe (Just x) = x
 
 
 -----------------------------------------------------------------------------------------

  {- A data type which depicts a play
    which a player can make on a board.
 -}   

 data PossMove = PossMove {
  dom :: Dom, -- The Dom for a given play
  end :: End, -- The end the play should be made at
  joinPip :: Int -- The value of the pip which joins the dom to the board
 } deriving (Show, Eq)
 
 
 -----------------------------------------------------------------------------------------
 {- The scoredAdvicePlayer player. This is the FINAL VERSION of the
    weightedPlayer. It decides which advisory function to play based on
    a weighting of each domino calculated from the domino's score and 
    the number of times it has been suggested.
 -}      
 scoredAdvicePlayer :: DomsPlayer
 
 scoredAdvicePlayer h b p s 
  | not(null wDom) =  (dom (head wDom),  end (head wDom))
  | not(null stopWin) = (dom (head stopWin), end (head stopWin))
  | not (null fiftyNineDoms) = (dom (head fiftyNineDoms), end (head fiftyNineDoms))
  | not (null hsDom) = (dom $ head hsDom, end $ head hsDom) 
  | not (null advice) = advice 
  | otherwise = (dom $ head rHsDom, end $ head rHsDom)
  where
   wDom = domWins b p h s
   stopWin = recklessHighScoreDom b p [(dom x)| x <- stopOpponentWin b p h s] s
   fiftyNineDoms = makeFiftyNine b p h s
   hsDom = highScoreDom b p h s
   rHsDom = recklessHighScoreDom b p h s   
   advice = weightedAdvice h b p s   
  
 {- The weightedAdvice function is an evaluation strategy which returns a domino
    which maximises the product of times suggested and the domino's score.
 -}   
 weightedAdvice :: Hand->DomBoard->Player->Scores->(Dom,End)
 
 weightedAdvice h b p s
  | null (sortedDoms) = (dom $ head possPlays, end $ head possPlays)
  | otherwise = let bestDom = (maximumBy (comparing length) sortedDoms) in ((dom $ head bestDom), (end $ head bestDom)) -- Play the most frequently occuring domino returned by the tactic.
  where
   (cpScore, enScore) = if(p == P1) then s else swap s -- Get the player's current score and the opponent's score.
   possPlays = getAllPlays b p h -- Get all moves the player can make
   rHsDom = recklessHighScoreDom b p h s
   majority = playMajority b p h s
   stitchDoms = opponentStitch b p h s
   knockOffDoms = knockOff b p h s
   bestGuess = (rHsDom ++ majority ++ stitchDoms ++ knockOffDoms) -- Get all of the advised dominoes.
   {- Repeat dominoes based on their score. E.g A domino which scores 2
      and has been returned three times will be found in scoredBestGuess
      2 * 3 = 6 times      
   -}
   scoredBestGuess = concat [replicate (scoreDom (dom x) (end x) b) x | x <- bestGuess, ((scoreDom (dom x) (end x) b) + cpScore <= 61)]
   sortedDoms = (group (sortBy (comparing dom) scoredBestGuess)) -- Group up the sets of dominoes

 -----------------------------------------------------------------------------------------
 
 {- The win player. A simple player which considers whether
    the player has a domino which they can use to win the game.
 -}
 winPlayer :: DomsPlayer
 
 winPlayer h b p s 
  | not(null wDom) =  (dom (head wDom),  end (head wDom)) -- If a winning domino is available. Play it.
  | otherwise = (dom $ head rHsDom, end $ head rHsDom) -- Otherwise play the highest scoring domino in the hand.
  where
   wDom = domWins b p h s -- Gets dominoes which will win the game 
   rHsDom = recklessHighScoreDomPrimitive b p h s -- Gets the highest scoring play in a hand
   
 {- The block player. A player which considers whether
    the player has a domino which they can use to block their
    opponent from winning the game.
 -}
 blockPlayer :: DomsPlayer
 
 blockPlayer h b p s 
  | not(null wDom) =  (dom (head wDom),  end (head wDom))
  | not(null stopWin) = (dom (head stopWin), end (head stopWin)) -- If a domino which stops the opponent from winning is available, play it.
  | otherwise = (dom $ head rHsDom, end $ head rHsDom)
  where
   wDom = domWins b p h s
   stopWin = recklessHighScoreDomPrimitive b p [(dom x)| x <- stopOpponentWin b p h s] s -- Get the highest scoring domino which stops the opponent winning. 
   rHsDom = recklessHighScoreDomPrimitive b p h s
    
 {- The FiveFour player. A  player which considers whether
    the player has the (5,4) domino which they can use to 
    gain the upper hand at the start of game.
 -}    
 fiveFourPlayer :: DomsPlayer
 
 fiveFourPlayer h b p s 
  | not(null initDom) = (dom (head initDom), end (head initDom)) -- If the four five is in hand on initial board, play it.
  | not(null wDom) =  (dom (head wDom),  end (head wDom))
  | not(null stopWin) = (dom (head stopWin), end (head stopWin))
  | otherwise = (dom $ head rHsDom, end $ head rHsDom)
  where
   initDom = dropFiveFour b p h s -- Find out whether the player posesses the Five Four
   wDom = domWins b p h s
   stopWin = recklessHighScoreDomPrimitive b p [(dom x)| x <- stopOpponentWin b p h s] s
   rHsDom = recklessHighScoreDomPrimitive b p h s   
    
 {- The FiftyNine player. A  player which considers whether
    the player can make a two step win, by achieving a score
    of fifty nine, then following up that play with a play
    of two.
 -}    
 fiftyNinePlayer :: DomsPlayer
 
 fiftyNinePlayer h b p s 
  | not(null wDom) =  (dom (head wDom),  end (head wDom))
  | not(null stopWin) = (dom (head stopWin), end (head stopWin))
  | not (null fiftyNineDoms) = (dom (head fiftyNineDoms), end (head fiftyNineDoms)) -- If a domino making the player's score up to 59 is available then play it.
  | otherwise = (dom $ head rHsDom, end $ head rHsDom)
  where
   wDom = domWins b p h s
   stopWin = recklessHighScoreDomPrimitive b p [(dom x)| x <- stopOpponentWin b p h s] s
   fiftyNineDoms = makeFiftyNine b p h s -- Get dominoes which make the player's score up to 59.
   rHsDom = recklessHighScoreDomPrimitive b p h s     
 
 {- The safeHSDPlayer player. A  player which considers whether
    there are any safe high scoring dominoes to play. Returns highest
    scoring domino where the opponent's subsequent play does not score
    higher.
 -}    
 safeHSDPlayer :: DomsPlayer
 
 safeHSDPlayer h b p s 
  | not(null wDom) =  (dom (head wDom),  end (head wDom))
  | not(null stopWin) = (dom (head stopWin), end (head stopWin))
  | not (null fiftyNineDoms) = (dom (head fiftyNineDoms), end (head fiftyNineDoms))
  | not (null hsDom) = (dom $ head hsDom, end $ head hsDom) -- Play the high scoring domino if available.
  | otherwise = (dom $ head rHsDom, end $ head rHsDom)
  where
   wDom = domWins b p h s
   stopWin = recklessHighScoreDomPrimitive b p [(dom x)| x <- stopOpponentWin b p h s] s
   fiftyNineDoms = makeFiftyNine b p h s
   hsDom = highScoreDomPrimitive b p h s -- Get highest scoring domino which cannot be beaten by opponent on their next turn.
   rHsDom = recklessHighScoreDomPrimitive b p h s       
       
 {- The polledPlayer player. A  player which polls advisory strategies to
    see which domino is most commonly suggested by the advisory tactics,
    shoudl the critical tactics fail.
 -}      
 polledPlayer :: DomsPlayer
 
 polledPlayer h b p s 
  | not(null wDom) =  (dom (head wDom),  end (head wDom))
  | not(null stopWin) = (dom (head stopWin), end (head stopWin))
  | not (null fiftyNineDoms) = (dom (head fiftyNineDoms), end (head fiftyNineDoms))
  | not (null hsDom) = (dom $ head hsDom, end $ head hsDom) 
  | not (null advice) = advice -- If the advisory strategy returns a domino then play it.
  | otherwise = (dom $ head rHsDom, end $ head rHsDom)
  where
   wDom = domWins b p h s
   stopWin = recklessHighScoreDomPrimitive b p [(dom x)| x <- stopOpponentWin b p h s] s
   fiftyNineDoms = makeFiftyNine b p h s
   hsDom = highScoreDomPrimitive b p h s
   rHsDom = recklessHighScoreDomPrimitive b p h s   
   advice = polledAdvice h b p s -- Get a fallback advisory play.
 
 {- The polledAdvice function is an evaluation strategy which decides which domino 
    to play by returning the most commonly suggested domino by the advisory tactics.
 -} 
 polledAdvice :: Hand->DomBoard->Player->Scores->(Dom,End)
 
 polledAdvice h b p s
  | null (sortedDoms) = (dom $ head possPlays, end $ head possPlays) -- No advice returned. Return first domino
  | otherwise = let bestDom = (maximumBy (comparing length) sortedDoms) in ((dom $ head bestDom), (end $ head bestDom)) -- Return the most common play suggested by advisory tactics
  where
   possPlays = getAllPlays b p h -- Get possible plays
   rHsDom = recklessHighScoreDomPrimitive b p h s -- Get the HSD  
   majority = playMajority b p h s -- Get dominoes where player holds pip majority
   stitchDoms = opponentStitch b p h s -- Get dominoes player can use to stitch opponent
   knockOffDoms = knockOff b p h s -- Get dominoes player knock on next play
   bestGuess = (rHsDom ++ majority ++ stitchDoms ++ knockOffDoms)
   scoredBestGuess = [x | x <- bestGuess, (scoreDom (dom x) (end x) b) > 0] -- Get all plays from the above which score.
   sortedDoms = (group (sortBy (comparing dom) scoredBestGuess)) -- Group the plays to sum them

 {- The aggressiveAdvice function is an evaluation strategy which returns the
    highest scoring play which has been suggested by the advisory tactics.
 -} 
 aggressiveAdvice :: Hand->DomBoard->Player->Scores->(Dom,End)

 aggressiveAdvice h b p s
  | null (aggressiveDom) = (dom $ head possPlays, end $ head possPlays)
  | otherwise = ((dom $ head aggressiveDom), (end $ head aggressiveDom)) -- Return best scoring play from advisory function
  where
   possPlays = getAllPlays b p h -- Get plays the player can make on the current board
   majority =   playMajority b p h s
   stitchDoms = opponentStitch b p h s
   knockOffDoms =  (knockOff b p h s)
   bestGuess = (majority ++ stitchDoms ++ knockOffDoms) -- Get plays from advisory functions
   allDoms = [dom x | x <- bestGuess]
   aggressiveDom = (recklessHighScoreDomPrimitive b p allDoms s) -- Get the highest scoring domino from advisory functions
   
 -----------------------------------------------------------------------------------------
    
 {- Tactic returning the highest scoring domino, where another player cannot 
  score higher on their next turn as a result of this and the domino does 
  not send the player bust.
 -}
 highScoreDom :: Tactic
 
 highScoreDom db p h s
  | (null bestPlays) = [] -- If there are no plays which can be made return the empty list.
  | otherwise = [ (snd ( maximumBy (comparing fst) bestPlays ))] -- Return the highest scoring domino which doesn't result in the other player scoring higher
  where
   (cpScore, enScore) = if(p == P1) then s else swap s -- Get the player's current score and the opponent's score.
   possPlays = getAllPlays db p h -- Get plays the player can make on the current board
   scoredPlays = [x| x@(s, m)<- (scorePlays p possPlays db), (s + cpScore) <= 61] -- Get the score resulting from playing each of these potential moves and check if move sends player bust.
   opponentPlayableHand = getOpponentDoms db h -- Get dominoes the opponent may posess.
   bestPlays = [x | x <- scoredPlays, opponentScoresHigher db (snd x) opponentPlayableHand p s] -- Return only the dominoes where the opponent cannot score higher on their next turn.

   
 {- Tactic returning the highest scoring domino, without regard for whether another player cannot 
  score higher on their next turn as a result of this and the domino does 
  not send the player bust.
 -}
 recklessHighScoreDom :: Tactic
 
 recklessHighScoreDom db p h s
  | (null scoredPlays) = [] -- If there are no plays which can be made return the empty list.
  | otherwise = [ (snd ( maximumBy (comparing fst) scoredPlays ))] -- Return the highest scoring domino which doesn't result in the other player scoring higher
  where
   (cpScore, enScore) = if(p == P1) then s else swap s -- Get the player's current score and the opponent's score.
   possPlays = getAllPlays db p h -- Get plays the player can make on the current board
   scoredPlays = [x| x@(s, m)<- (scorePlays p possPlays db), (s + cpScore) <= 61] -- Get the score resulting from playing each of these potential moves and check if move sends player bust.
  
 {- A primitive version of the HSD tactic used by the earlier versions of the player.
    does not account for going bust. See comments for version above. Changes noted.
 -}
 highScoreDomPrimitive :: Tactic
 
 highScoreDomPrimitive db p h s
  | (null bestPlays) = [] 
  | otherwise = [ (snd ( maximumBy (comparing fst) bestPlays ))] 
  where
   (cpScore, enScore) = if(p == P1) then s else swap s 
   possPlays = getAllPlays db p h 
   scoredPlays = [x| x@(s, m)<- (scorePlays p possPlays db)]
   opponentPlayableHand = getOpponentDoms db h 
   bestPlays = [x | x <- scoredPlays, opponentScoresHigher db (snd x) opponentPlayableHand p s] -- Does not check for going bust.

   
 {- A primitive version of the recklessHSD tactic used by the earlier versions of the player.
    does not account for going bust. See comments for version above. Changes noted.
 -}
 recklessHighScoreDomPrimitive :: Tactic
 
 recklessHighScoreDomPrimitive db p h s
  | (null scoredPlays) = [] 
  | otherwise = [ (snd ( maximumBy (comparing fst) scoredPlays ))] 
  where
   (cpScore, enScore) = if(p == P1) then s else swap s 
   possPlays = getAllPlays db p h 
   scoredPlays = [x| x@(s, m)<- (scorePlays p possPlays db)] -- Does not check for going bust      

   
 {- auxiliary  function for highScoreDom gets potential 
    opponent scores on next turn following a potential 
    play by the current player.
 -}  
 opponentScoresHigher :: DomBoard -> PossMove -> Hand -> Player -> Scores -> Bool
 
 opponentScoresHigher db pm h p s
  | not (null scoredPlays) = (maximum scoredPlays) <= (scoreboard newBoard) -- Return True if current player will be in the lead.
  | otherwise = False -- Return False. The opponent cannot make a turn.
  where
   (cpScore, enScore) = if(p == P1) then s else swap s  
   opponentP = if(p == P1) then P2 else P1  
   newBoard@(Board le re _) = (resMaybe (playDom p (dom pm) (end pm) db)) -- Get the board after current player has made their move.
   possPlays = [getPlayInfo newBoard L x | x <- h, goesLP x newBoard] ++ [getPlayInfo newBoard R x | x <- h, goesRP x newBoard] -- Get the dominoes the opponent could possibly have.
   scoredPlays = [scoreboard (resMaybe (playDom (opponentP)(dom x) (end x) newBoard))|x <- possPlays] -- Get the scores for the opponent after each possible play is made. 
 
  {- auxiliary  function which returns tuples of a score and
     the possMove that resulted in this score.
 -}
 scorePlays :: Player -> [PossMove] -> DomBoard -> [(Int, PossMove)]
 
 scorePlays p pm db = [((scoreDom (dom play) (end play) db) , play)  |   play <- pm]
 
 -----------------------------------------------------------------------------------------
 
 {- Tactic which will play (4,5) on an empty board
    provided this domino is in the player's hand
 -}
 dropFiveFour :: Tactic
 
 dropFiveFour (Board _ _ _) _ _ _ = [] -- We don't want to return the (5,4) if the game is already in play. 
 dropFiveFour InitBoard p h s 
  | elem (5,4) h = [(PossMove (5,4) L 5)] -- If we're on the Initial board and (5,4) is available, we should play in
  | otherwise = [] -- (5,4) isn't available. Return nothing.
 
 -----------------------------------------------------------------------------------------
 
 {- Tactic which will return a domino which wins the game
    should the player posess such a domino.
 -}
 domWins :: Tactic
 
 domWins InitBoard _ _ _ = [] -- Cannot win from the initial board.
 domWins db p h s = [x | x <- possPlays, ((scoreDom (dom x) (end x) db) + cpScore )== 61] -- Return dominoes which when played on the board score a total of 61
  where 
  possPlays = getAllPlays db p h -- Return all playable moves for the current hand.
  (cpScore, enScore) = if(p == P1) then s else swap s -- Get the player's current score and the opponent's score.
  
 -----------------------------------------------------------------------------------------
 
 {- Tactic which will return a domino which gives a score of 
    59 should the player posess such a domino. As such a score
    has a high chance of returning a winning domino on the 
    next turn.
 -}
 makeFiftyNine :: Tactic 
 
 makeFiftyNine InitBoard _ _ _ = [] -- Cannot score 59 from the initial board.
 makeFiftyNine _ _ _ ( 59,_) = []
 makeFiftyNine db@(Board le re _) p h s 
  | cpScore < 51 = [] -- If the player's score is less than 51 there is no point in checking for doms
  | otherwise = [x | x <- scoreFiftyNine, not (null(domWins (resMaybe (playDom p (dom x) (end x) db)) p (handMinusMove h x) (59, enScore)))] -- Return only plays which bring the score to 59 if they can then bring the score to 61.
  where 
   possPlays = getAllPlays db p h -- Get the possible plays that the player can make.
   (cpScore, enScore) = if(p == P1) then s else swap s -- Get the scores for the current player and their opponent.
   scoreFiftyNine = [x | x <- possPlays, (scoreDom (dom x) (end x) db) + cpScore == 59] -- Try each possible play and return those which bring score to 59
 
  {- Returns a hand without a domino in a given move
  -}
 handMinusMove :: Hand -> PossMove -> Hand
 handMinusMove h pm = [x | x <- h, not (x == (dom pm))] 
  
 -----------------------------------------------------------------------------------------
 
 {- Tactic which will return playable dominoes for which the 
    player posesses the majority of a given pip. [Not tested beyond here...]
 -}
 playMajority :: Tactic
 
 playMajority _ _ [] _ = []
 playMajority db p h s  = domsToPlay
  where
   possPlays = getAllPlays db p h -- Get all of the dominoes the player can play from their hand.
   possDoms = [x | x <- h, goesLP x db] ++ [x | x <- h, goesRP x db] -- Get all of the playable dominoes in a hand
   sortedPips = sort ( concat (unzip (h) )) -- Unzip tuples into a list of pips 
   bestPip = bestPipVal sortedPips -- Get a list of pips sorted by rarity returned as (pip, number of occurences)
   domsToPlay = bestWithMajority possPlays bestPip -- Get the best playable pip for which the player has a majority.
  
  
 {- auxiliary  function for playMajority which gets a list of moves
    that the player could make where the played domino will have a complement
    in the next hand.
 -}    
 bestWithMajority :: [PossMove] -> [(Int, Int)] -> [PossMove]
 
 bestWithMajority _ [] = [] -- List Of pips is empty. Return nothing.
 bestWithMajority pm ((bp, _) : bs)
  | not(null (getPlaysWithPip pm bp)) = getPlaysWithPip pm bp --If plays for the current pip exist. Return them.
  | otherwise =  bestWithMajority pm bs -- Otherwise check for plays on the next best pip.


 {- auxiliary  function for playMajority which gets the number of
    occurences for each pip value in the hand. Returns as a tuple
 -}  
 bestPipVal :: [Int] -> [(Int, Int)]
 
 bestPipVal [] = [] -- Pip list is empty. Return nothing.
 bestPipVal n = sortBy (comparing snd) [(pip, length pipVal) | pipVal@(pip : _) <- l, (length pipVal) >= 3] -- Return tuples of (pip, number of occurences) where the given pip occurs more than three times
  where 
   l = (group n) -- Group the pips into sub-lists of the same value.
 
 
 {- auxiliary  function for playMajority which gets plays from
    a set of possible moves where the open pip on a play is
    equal to the given integer.
 -}  
 getPlaysWithPip :: [PossMove] -> Int -> [PossMove]  
 
 getPlaysWithPip pm n = [x | x <- pm, openPip x == n] -- Filter the list of moves returning only dominoes with a matching open end.
 
 -----------------------------------------------------------------------------------------
 
 {- Tactic which will return a domino which the player
    can play to block their opponent from winning the game.
 -}
 stopOpponentWin :: Tactic
 
 stopOpponentWin db p [] s = [] -- Player's hand is empty. Return empty list.
 stopOpponentWin InitBoard _ _ s = [] -- Opponent can't win on first move. Return empty list.
 stopOpponentWin db@(Board le re _) p h s   
  | enScore < 53 = []
  | otherwise = [ (x) | x <- possPlays, (null (domWins (resMaybe (playDom p (dom x) (end x) db)) (opponentP) opponentPlayableHand s))] -- Find plays for which the opponent can no longer win the next game
  where
   (cpScore, enScore) = if(p == P1) then s else swap s
   possPlays = getAllPlays db p h -- Get possible domino plays possible from the current hand.
   opponentP = if(p == P1) then P2 else P1  -- Get opponent by cycling enumerable.
   opponentPlayableHand = getOpponentDoms db h -- Get Dominoes opponent could play on current board (Hand)
   {- Filter list of plays to only include those which mean the opponent can no longer win by performing domWin
      on the hand of the enemy. If doms return from this, the move does not prevent a win. -}
   stopWin = [x | x <- possPlays, (null (domWins (resMaybe (playDom p (dom x) (end x) db)) (opponentP) opponentPlayableHand s))] 
  
 -----------------------------------------------------------------------------------------
  
  {- Tactic which will return dominoes which the player
    can play to try to stitch their opponent. 
 -}
 opponentStitch :: Tactic
 
 opponentStitch db p h s = [x | x <- possPlays, (stitchPlays p db x opponentPlayableDoms (end x)) == 0] -- Return dominoes which when played, stop the player's opponent making a move at the same end
  where 
   possPlays = getAllPlays db p h -- Get all possible plays in the current hand
   opponentP = if(p == P1) then P2 else P1  -- Get opponent
   opponentPlayableDoms = getOpponentDoms db h -- Get dominoes not in history and not in player hand
   
   
  {- auxiliary  function for opponentStitch which returns
     the number of moves a player's opponent can make when
     after a player makes a move on the board.
 -}  
 stitchPlays :: Player -> DomBoard -> PossMove -> Hand -> End -> Int
 
 stitchPlays p db pm oph e
  | e == L = length [x | x <- oph, goesLP x newBoard] -- If the given end is left, get dominoes which the opponent can play on the left.
  | otherwise = length [x | x <- oph, goesRP x newBoard] -- Otherwise get dominoes the opponent could play on the right.
  where 
   newBoard = resMaybe (playDom p (dom pm) (end pm) db) -- Play the Possible Move on the current board and return the new board.
   
 -----------------------------------------------------------------------------------------
 
 {- Tactic which will return dominoes which the player
    can play to knock off their previous play. 
 -}
 knockOff :: Tactic 
 
 knockOff db p h s
  | null possWithComplement = []
  | otherwise = possWithComplement
  where 
   possPlays = getAllPlays db p h -- Get plays which can be made on the current board.
   {- Get dominoes which have a complement on the board. By playing each play on the board, 
      then checking how many sebsequent plays can be made on the same end to follow it. If 
      more than one subsequent play, this domino has a "knock off".
   -}
   possWithComplement = [x| x <- possPlays, length (getPlaysAtEnd (resMaybe(playDom p (dom x) (end x) db)) p h (end x)) > 1]
 
 -----------------------------------------------------------------------------------------
 -- Misc Auxillary Functions. These help the tactics do things.
 
 
 {- An auxiliary  function which aquires a list
    of dominoes which a player's opponent may
    have. This is based on history of dominoes
    played, and those that are already in the 
    current player's possession.
 -}   
 getOpponentDoms :: DomBoard -> Hand -> Hand
 
 getOpponentDoms InitBoard h = [d|d <- domSet, not (elem d h)] -- On the initial board the opponent could have any domino that isn't in player hand
 getOpponentDoms db@(Board le re his) h = [d|d <- domSet, not (elem d toAvoid)] -- If the domino in question isn't in the list of doms with known placement. Add it to opponent's hand.
  where
  toAvoid = getDomsFromHist his ++ h -- Create a list of dominoes the opponent doesn't have from history  

  
 {- An auxiliary  function returns all
    dominoes which have already been 
    played on the board from the history.
 -}    
 getDomsFromHist :: History -> [Dom]
 
 getDomsFromHist [] = [] -- Empty history return empty list.
 getDomsFromHist his@((d, p, m) : hs) =  [d] ++ getDomsFromHist hs -- Recursively iterate through each item in the history, returning the domino for each.
    
 {- Gets all PossMoves on the current board.
 -} 
 getAllPlays :: DomBoard -> Player -> Hand -> [PossMove]
 
 getAllPlays db p h = getPlaysAtEnd db p h L ++ getPlaysAtEnd db p h R 
   
  {- A function which returns PossMoves for domioes
     in a player's hand which are playable at a given
     end.
 -}   
 getPlaysAtEnd :: DomBoard -> Player -> Hand -> End -> [PossMove]
 
 getPlaysAtEnd db p h L = [getPlayInfo db L x | x <- h, goesLP x db]
 getPlaysAtEnd db p h R = [getPlayInfo db R x | x <- h, goesRP x db]

 
 {- A function which returns the pip which will
     be "open" on the given board (at the end for
     other dominoes to connect to).
 -}   
 openPip :: PossMove -> Int
 
 openPip (PossMove (l, r) e jp)
  | l == jp = r 
  | otherwise = l 
 
 {- Converts a domino into a PossMove
    taking the domino and end which it
    should be played at and deciding on
    the joining pip from this.
 -} 
 getPlayInfo :: DomBoard -> End -> Dom -> PossMove
 
 getPlayInfo InitBoard e d@(p1, _) = (PossMove d L p1)
 getPlayInfo db@(Board _ (r1, r2) _) R d@(p1,p2)
  | p1 == r1 = (PossMove d R p1)
  | p2 == r1 = (PossMove d R p2)
  | p1 == r2 = (PossMove d R p1)
  | otherwise = (PossMove d R p2)
 getPlayInfo db@(Board (l1, l2) _ _) L d@(p1,p2)
  | p1 == l1 = (PossMove d L p1)
  | p2 == l1 = (PossMove d L p2)
  | p1 == l2 = (PossMove d L p1)
  | otherwise = (PossMove d L p2) 
 
 -----------------------------------------------------------------------------------------
 {- DomsPlayer
    given a Hand, the Board, which Player this is and the current Scores
    returns a Dom and an End
    only called when player is not knocking
    made this a type, so different players can be created
 -}
 
 type DomsPlayer = Hand->DomBoard->Player->Scores->(Dom,End)
 
 {- variables
     hand h
     board b
     player p
     scores s
 -}

 -- example players
 -- randomPlayer plays the first legal dom it can, even if it goes bust
 
 randomPlayer :: DomsPlayer

 randomPlayer h b p s 
  |not(null ldrops) = ((head ldrops),L)
  |otherwise = ((head rdrops),R)
  where
   ldrops = leftdrops h b
   rdrops = rightdrops h b
   
 -- hsdplayer plays highest scoring dom
 -- we have  hsd :: Hand->DomBoard->(Dom,End,Int)
 
 hsdPlayer h b p s = (d,e)
                     where (d,e,_)=hsd h b
                     
  -- highest scoring dom

 hsd :: Hand->DomBoard->(Dom,End,Int)
 
 hsd h InitBoard = (md,L,ms)
  where
   dscores = zip h (map (\ (d1,d2)->score53 (d1+d2)) h)
   (md,ms) = maximumBy (comparing snd) dscores
   
 
 hsd h b = 
   let
    ld=  leftdrops h b
    rd = rightdrops h b
    lscores = zip ld (map (\d->(scoreDom d L b)) ld) -- [(Dom, score)]
    rscores = zip rd (map (\d->(scoreDom d R b)) rd)
    (lb,ls) = if (not(null lscores)) then (maximumBy (comparing snd) lscores) else ((0,0),-1) -- can't be chosen
    (rb,rs) = if (not(null rscores)) then (maximumBy (comparing snd) rscores) else ((0,0),-1)
   in
    if (ls>rs) then (lb,L,ls) else (rb,R,rs)
 
 
                                               
 -----------------------------------------------------------------------------------------
 {- top level fn
    args: 2 players (p1, p2), number of games (n), random number seed (seed)
    returns: number of games won by player 1 & player 2
    calls playDomsGames giving it n, initial score in games and random no gen
 -} 
 
 domsMatch :: DomsPlayer->DomsPlayer->Int->Int->(Int,Int)
 
 domsMatch p1 p2 n seed = playDomsGames p1 p2 n (0,0) (mkStdGen seed)
 
 -----------------------------------------------------------------------------------------
 
{- playDomsGames plays n games

  p1,p2 players
  (s1,s2) their scores
  gen random generator
-}
 
 playDomsGames :: DomsPlayer->DomsPlayer->Int->(Int,Int)->StdGen->(Int,Int)
 
 playDomsGames _ _ 0 score_in_games _ = score_in_games -- stop when n games played
 
 playDomsGames p1 p2 n (s1,s2) gen 
   |gameres==P1 = playDomsGames p1 p2 (n-1) (s1+1,s2) gen2 -- p1 won
   |otherwise = playDomsGames p1 p2 (n-1) (s1,s2+1) gen2 -- p2 won
  where
   (gen1,gen2)=split gen -- get 2 generators, so doms can be reshuffled for next hand
   gameres = playDomsGame p1 p2 (if (odd n) then P1 else P2) (0,0) gen1 -- play next game p1 drops if n odd else p2
 
 -----------------------------------------------------------------------------------------
 -- playDomsGame plays a single game - 61 up
 -- returns winner - P1 or P2
 -- the Bool pdrop is true if it's p1 to drop
 -- pdrop alternates between games
 
 playDomsGame :: DomsPlayer->DomsPlayer->Player->(Int,Int)->StdGen->Player
 
 playDomsGame p1 p2 pdrop scores gen 
  |s1==61 = P1
  |s2==61 = P2
  |otherwise = playDomsGame p1 p2 (if (pdrop==P1) then P2 else P1) (s1,s2) gen2
  where
   (gen1,gen2)=split gen
   (s1,s2)=playDomsHand p1 p2 pdrop scores gen1  
  
 -----------------------------------------------------------------------------------------
 -- play a single hand
  
 playDomsHand :: DomsPlayer->DomsPlayer->Player->(Int,Int)->StdGen->(Int,Int)
 
 playDomsHand p1 p2 nextplayer scores gen = 
   playDoms p1 p2 init_gamestate
  where
   spack = shuffleDoms gen
   p1_hand = take 9 spack
   p2_hand = take 9 (drop 9 spack)
   init_gamestate = (p1_hand,p2_hand,nextplayer,InitBoard,scores) 
   
 ------------------------------------------------------------------------------------------   
 -- shuffle 
 
 shuffleDoms :: StdGen -> [Dom]

 shuffleDoms gen =  
  let
    weights = take 28 (randoms gen :: [Int])
    dset = (map fst (sortBy  
               (\ (_,w1)(_,w2)  -> (compare w1 w2)) 
               (zip domSet weights)))
  in
   dset
   
 ------------------------------------------------------------------------------------------
 -- playDoms runs the hand
 -- returns scores at the end

 
 playDoms :: DomsPlayer->DomsPlayer->GameState->(Int,Int)
 
 playDoms _ _ (_,_,_,_, (61,s2)) = (61,s2) --p1 has won the game
 playDoms _ _ (_,_,_,_, (s1,61)) = (s1,61) --p2 has won the game
 
 
 playDoms p1 p2 gs@(h1,h2,nextplayer,b,scores)
  |(kp1 &&  kp2) = scores -- both players knocking, end of the hand
  |((nextplayer==P1) && (not kp1)) =  playDoms p1 p2 (p1play p1 gs) -- p1 plays, returning new gameState. p2 to go next
  |(nextplayer==P1) = playDoms p1 p2 (p2play p2 gs) -- p1 knocking so p2 plays
  |(not kp2) = playDoms p1 p2 (p2play p2 gs) -- p2 plays
  |otherwise = playDoms p1 p2 (p1play p1 gs) -- p2 knocking so p1 plays
  where
   kp1 = knocking h1 b -- true if p1 knocking
   kp2 = knocking h2 b -- true if p2 knocking
   
 ------------------------------------------------------------------------------------------
 -- is a player knocking?

 knocking :: Hand->DomBoard->Bool
 
 knocking h b = 
  ((null (leftdrops h b)) && (null (rightdrops h b))) -- leftdrops & rightdrops in doms.hs
 
 ------------------------------------------------------------------------------------------
   
 -- player p1 to drop
 
 p1play :: DomsPlayer->GameState->GameState
 
 p1play p1 (h1,h2,_,b, (s1,s2)) = 
  ((delete dom h1), h2, P2,(updateBoard dom end P1 b), (ns1, s2))
   where
    (dom,end) = p1 h1 b P1 (s1,s2)-- call the player, returning dom dropped and end it's dropped at.
    score = s1+ (scoreDom dom end b) -- what it scored
    ns1 = if (score >61) then s1 else score -- check for going bust
    
 
 -- p2 to drop
   
 p2play :: DomsPlayer->GameState->GameState
 
 p2play p2 (h1,h2,_,b,(s1,s2)) = 
  (h1, (delete dom h2),P1, (updateBoard dom end P2 b), (s1, ns2))
  where
   (dom,end) = p2 h2 b P2 (s1,s2)-- call the player, returning dom dropped and end it's dropped at.
   score = s2+ (scoreDom dom end b) -- what it scored
   ns2 = if (score >61) then s2 else score -- check for going bust
 
   -------------------------------------------------------------------------------------------
 -- updateBoard 
 -- update the board after a play
 
 updateBoard :: Dom->End->Player->DomBoard->DomBoard
 
 updateBoard d e p b
  |e==L = playleft p d b
  |otherwise = playright p d b

  ------------------------------------------------------------------------------------------
 -- doms which will go left
 leftdrops :: Hand->DomBoard->Hand
 
 leftdrops h b = filter (\d -> goesLP d b) h
 
 -- doms which go right
 rightdrops :: Hand->DomBoard->Hand
 
 rightdrops h b = filter (\d -> goesRP d b) h 
 
 -------------------------------------------------
 -- 5s and 3s score for a number
  
 score53 :: Int->Int
 score53 n = 
  let 
   s3 = if (rem n 3)==0 then (quot n 3) else 0
   s5 = if (rem n 5)==0 then (quot n 5) else 0 
  in
   s3+s5
   
 ------------------------------------------------ 
 -- need comparing
 -- useful fn specifying what we want to compare by
 comparing :: Ord b=>(a->b)->a->a->Ordering
 comparing f l r = compare (f l) (f r)
 
 ------------------------------------------------
 -- scoreDom
 -- what will a given Dom score at a given end?
 -- assuming it goes
 
 scoreDom :: Dom->End->DomBoard->Int
 
 scoreDom d e b = scoreboard nb
                  where
                  (Just nb) = (playDom P1 d e b) -- player doesn't matter
 
 ----------------------------------------------------                 
 -- play to left - it will go
 playleft :: Player->Dom->DomBoard->DomBoard
 
 playleft p (d1,d2) InitBoard = Board (d1,d2) (d1,d2) [((d1,d2),p,1)]
 
 playleft p (d1,d2) (Board (l1,l2) r h)
  |d1==l1 = Board (d2,d1) r (((d2,d1),p,n+1):h)
  |otherwise =Board (d1,d2) r (((d1,d2),p,n+1):h)
  where
    n = maximum [m |(_,_,m)<-h] -- next drop number
    
 -- play to right
 playright :: Player->Dom->DomBoard->DomBoard
 
 playright p (d1,d2) InitBoard = Board (d1,d2) (d1,d2) [((d1,d2),p,1)]
 
 playright p (d1,d2)(Board l (r1,r2) h)
  |d1==r2 = Board l (d1,d2) (h++[((d1,d2),p,n+1)])
  |otherwise = Board l (d2,d1) (h++[((d2,d1),p,n+1)])
  where 
    n = maximum [m |(_,_,m)<-h] -- next drop number
 
 ------------------------------------------------------
 -- predicate - will given domino go at left?
 -- assumes a dom has been played
 
 goesLP :: Dom->DomBoard->Bool
 
 goesLP _ InitBoard = True
 
 goesLP (d1,d2) (Board (l,_) _ _) = (l==d1)||(l==d2)


 -- will dom go to the right?
 -- assumes a dom has been played
 
 goesRP :: Dom->DomBoard->Bool
 
 goesRP _ InitBoard = True
 
 goesRP (d1,d2) (Board _ (_,r) _) = (r==d1)||(r==d2)
 
 ------------------------------------------------

 -- playDom
 -- given player plays
 -- play a dom at left or right, if it will go

 
 playDom :: Player->Dom->End->DomBoard->Maybe DomBoard
 
 playDom p d L b
   |goesLP d b = Just (playleft p d b)
   |otherwise = Nothing
 
 playDom p d R b
   |goesRP d b = Just (playright p d b)
   |otherwise = Nothing
   
 ---------------------------------------------------    
 -- 5s & threes score for a board
 
 scoreboard :: DomBoard -> Int
 
 scoreboard InitBoard = 0

 scoreboard (Board (l1,l2) (r1,r2) hist)
  |length hist == 1 = score53 (l1+l2) -- 1 dom played, it's both left and right end
  |otherwise = score53 ((if l1==l2 then 2*l1 else l1)+ (if r1==r2 then 2*r2 else r2))   