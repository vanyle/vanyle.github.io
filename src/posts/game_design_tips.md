{%
setvar("layout",theme .. ".html")
%}

# How to make compelling games?
*A game design idea concept I realized*

There is this talk I really like from Jonathan Blow about making interesting games.

The video is long, but in summary, he talks about emerging properties of simple systems and how this emergence is what makes the systems
of a game interesing.

<iframe width="350" height="200" src="https://www.youtube.com/embed/C5FUtrmO7gI?si=v5EE53Oed7d0v2A2" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

This is true, but how do you create interesting systems?

I will specifically write about high level systems and not things like "juice" and "impact" which are also important but in my opinion, they are meant to attract a player to a game, but they won't keep him playing for a long time.

To investigate, let's consider board games, and specifically card games using a [standard 52 cards deck](https://en.wikipedia.org/wiki/Standard_52-card_deck).

I love prototyping games using these cards as there is a surprising large design space with only 52 different cards and testing is easy as you can find these
decks pretty much everywhere.

But before creating our own game, let's first consider existing successful games.

## Poker

One example is [Poker](https://en.wikipedia.org/wiki/Poker). To simplify the rules, in poker, you get 5 cards in your hand and 2 cards on the table visible to everyone.

Poker provides a function that assigns a score to every set of 5 cards (this is a weird way of simply saying that hands are well-ordered, and some players
can have better hands than other depending on their content.)

Players bet money during multiple rounds depending on their hand content. If a player is not willing to bet as much as the other, he drops from the round.
If there is one player left, he wins all the money bet during the round without even revealing his hand.
If there are multiple players left after they reveal their hand and the player with the best hand wins the stake.

I believe that what make poker interesting is:

### Player interaction

People are naturally complex and unpredictable. Poker is complicated from a game-theory standpoint as the probability are hard to measure and human psychology
plays a big role in how other will behave preventing your from consistently guessing their hand (except if you are a poker expert).

### Large state space

The state space of the game is the number of possible states the game can be in. In a poker game with 4 players, 20 cards are hidden and 2 cards are visible.

The state space is thus: $${52 \choose 5} \times {47 \choose 5} \times {42 \choose 5} \times {37 \choose 5} \times {35 \choose 2} = \sim 10^{26}$$

The largest state space for a card game is \\\[52! = \sim 10^{67} \\\].
Logarithmically speaking, poker is about a third of that which is not bad!

### Rule simplicity

The rules of poker are very manageable. Once you learn how to compute the value of a hand (which is simple, there are high cards, one pair, two pair, three of a kind, straight, flush, full house, four of a kind, and straight flush, play some [balatro](https://www.playbalatro.com/) to learn the basic poker hands), you know
how to play.

## What can be learn from this?

The single biggest insight is state space. For a game to be interesting, it needs to have a state space that is large, but easy to describe.

Take for example Chess. What makes chess so complex but simple is that the state space is large (there are 32 pieces that can occupy 64 spaces, [the state space](https://en.wikipedia.org/wiki/Shannon_number) is about $\sim 10^{43}$). But this space is easy to describe, I just did so by stating that a state is the position of the 32 pieces on an 8x8 board (we'll ignore castling, en-passant and other rules...)

In a card game, the state is usually the cards the players are holding. While you could argue that the order of the cards in the deck is also part of the state, this order is so random that strategies cannot be built around it so I am not counting it.

Consider the following 4-player game:

Every card represent 1 gold. Everybody starts with 1 gold. The first player to 5 gold wins. Every turn you can draw a card to earn one gold or make a player of your choice discard a card.

While it has a bit of complexity because you can interact with other player to form alliances, it is boring because the state space is very small.
Every player can have between 0 and 4 cards, so the state space is 20 (or even less if you assume players are indistinguishable).

But if you change the game so that 1 card represent as much gold as the number of it (Jack = 11, Queen = 12, King = 13), and the goal is to at least reach 30 but not exceed 40, the state space increases a lot as cards are no longer indistinguisable and the game becomes a more strategic and interesting (as you can lie about your card count and still make strategies)

The game is still not great as every player only has a few options every turn but it could be the start of the rules of an interesting card game.

The larger the state, the easier it is to introduce creative gameplay mechanics. A mechanic is simply a rule of the form: If we are in this place in the state space, the player can / must move to this state.

In the first game, if we want to add rules, we can only put the amount of gold the player has. In the second game, we can put specific events or options that occur at specific gold amounts.

# Applying what we learn to video games

When making single player videogames, we cannot use other players as design elements so making a game with interesting gameplay is harder, but we can reuse the previous concepts:

- Have a large state space
- Always offer multiple non-trivial options to the player
- Short term consequences of action should be easy to predict but long term consequences should be harder to predict.

All in all, the game should be a large [chaotic system](https://en.wikipedia.org/wiki/Chaos_theory) with a [Lyapunov time](https://en.wikipedia.org/wiki/Lyapunov_time) of a few minutes.

## A platformer

In a basic platformer, the state space is the position of the player which is only 2 numbers! To increase this state space, one possibility is to add powerups / an inventory.

We could also add enemies / allies, so that their position increase the state space.

Finally, the player could interact with the terrain and the platforms!

## A strategy game

Strategy games naturally have a large state space as the position of your units or building form a big amount of possibility.

I believe that this makes strategy games easier to make interesting. Even though this makes them harder to balance, this is not an issue.

- If a game is too easy, it will still be played by people looking for a power-fantasy time of experience
- If it is too hard, it will be played by dark-souls-enjoying players looking for a challenge.

# Conclusion

When designing games, start by choosing a state space. If you find that your game lacks depth, try to increase this state space as much as possible without adding too much complexity to the rules (or have the rules make intuitive sense).

Ideas that can work to increase state space:

- Adding a status/powerup effect system to players / units / enemies.
- Adding an inventory system
- Adding another dimension (rarely works but still listed)
- Add a way of combining existing elements (item crafting, enemies merging, combos in fighting games, etc...)
