

unit = 254
unit = unit/2

maxEnergy = unit
minEnergy = -unit

nowEnergy = 0
memState = []
memResult = []
memPlan = []

threshold = 0.8

urgency= (limit, threshold, now) ->
    urgncy = Math.abs(limit*threshold-now)
    say = ""
    for i in [0...urgncy]
        exponential = Math.pow 2,i
        for letter in [0...exponential]
            say = say+"!"
    return exponential

lowerEnergy= ->
    nowEnergy -= 1

# Entropie
setInterval lowerEnergy, 1000


class Brain
    constructor: ->
        @trust = 111
        @id = generateUUID()
        @puls = 1000

    born: ->
        setInterval @live, @puls

    checkState: ->
        nowState = new State
        nowState.energy = nowEnergy
        memState.push nowState
        return nowState

    live: =>
        ################################
        if nowEnergy == minEnergy
            return
        ################################
        meme = memPlan.shift()
        console.log meme
        
        # start Timemeasurement to find out duration of the task
        startTime = (new Date).getTime()
        # run the task
        # for i in meme.task
        eval(meme.task)
        result = @checkState()
        console.log result
        endTime = (new Date).getTime()
        meme.duration = endTime-startTime

        # update how much we trust this concept
        if result.energy isnt meme.expectedResult.energy
            console.log "unexpected energylevel! #{meme.expectedResult.energy}=#{result.energy}"
            meme.trust -= 1
        else
            console.log "expected energylevel! #{meme.expectedResult.energy}=#{result.energy} Im so good!"
            meme.trust += 1


        # save the Result of this run
        updatedMeme = new Meme meme, meme.task, result
        updatedMeme.duration = meme.duration
        memResult.push updatedMeme

        ##################################
        ## What to do next ??? ###########
        ##################################

        panic = no
        # find out how much idle time we will have
        if memResult.length > 1
            oldRun = memResult[memResult.length-1]          
            olderRun = memResult[memResult.length-2]
            diffRun = olderRun.time - oldRun.time
            idleTime = Math.abs(diffRun)-meme.duration
            # I Overload 5% tolerance
            if @puls/diffRun > -0.95
                panic = yes

        # If we panic we will do something! no matter what!
        if memState.length > 2
            tendenceEnergy = 0
            for i in [0...memState.length-1]
                tendenceEnergy += memState[i+1].energy-memState[i].energy
            tendenceEnergy=tendenceEnergy/memState.length
            tendenceEnergy=Math.round(tendenceEnergy)
            
            if tendenceEnergy < 0 
                if panic is yes and nowEnergy < 0
                    console.error "PANIC!!! #{@puls/realPuls}"
                    updatedMeme.expectedResult.energy += tendenceEnergy
                    memPlan.push updatedMeme
                else
                    updatedMeme.expectedResult.energy += tendenceEnergy
                    memPlan.push updatedMeme

                
                # EFFECTIVE ---------------------------------
                # find a point in memState when energy was raised
                # save the found timestamp and the raiseamount
                # sort out when the highest raise happened

                # If we couldn't find anything
                # try something random
                
                # EFFICIENT ---------------------------------
                # find a meme with nearly the same timestamp
                # save the found meme into an array
                # check the trust of this meme

                # PREDICT -------------------------------------
                # Find out how much time we have before we hit minEnergy
                # Find out how many cycles that is with the current pulse

                # For i in cycles
                # plan memes as found in above
                # if our selftrust is higher than the memetrust
                # PLAN THE MEMES IN A NEW MEME! Not directly in the main memPlan

            if tendenceEnergy > 0 
                if panic is yes and nowEnergy > 0
                    console.error "PANIC!!! #{@puls/realPuls}"    
                    updatedMeme.expectedResult.energy += tendenceEnergy
                    memPlan.push updatedMeme
                else
                    updatedMeme.expectedResult.energy += tendenceEnergy
                    memPlan.push updatedMeme

            if tendenceEnergy is 0
                memPlan.push updatedMeme

        # # we have no memory of states... Amnesia?
        else
            memPlan.push updatedMeme
    

#
# A thought or cascade of thoughts or concept
# @origin: I know where this thought came about ...
# @trust:  I have a certain trust of the outcome ...
# @result: I expect a outcome of this which is ...
#  
class Meme 
    constructor: (origin,task,expectedResult) ->
        @id = generateUUID()
        @trust = origin.trust
        @origin = origin.id
        @task = task
        @expectedResult = expectedResult
        @time = (new Date).getTime()
        @duration = undefined

#
# My current state depending on sensory input
#
class State
    constructor: ->
        #console.log "State constructor ***"
        @temperature = 0
        @energy = 0
        @position = [0,0,0]
        @time = (new Date).getTime()

class memTask

    raise: ->
        console.log "Ich verbrenne Fett zu Energie!"
        costEnergy = +1
        nowEnergy += costEnergy

    idle: ->
        console.log "Ich idle!"


Me = new Brain
# Memory of tasks
memTask = new memTask

# Meme of checking energy
raiseEnergyMeme = new Meme Me, "memTask.raise()",new State
idleMeme = new Meme Me, "memTask.idle()",new State

# Plan for life
memPlan.push idleMeme

Me.born()
