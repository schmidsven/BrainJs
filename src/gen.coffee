###
# Thanks to...
*
* Regression.JS - Regression functions for javascript
* http://tom-alexander.github.com/regression-js/
* 
* copyright(c) 2013 Tom Alexander
* Licensed under the MIT license.
*
*
###


# attach the .equals method to Array's prototype to call it on any array
Array::equals = (array) ->
  # if the other array is a falsy value, return
  if !array
    return false
  # compare lengths - can save a lot of time 
  if @length != array.length
    return false
  i = 0
  l = @length
  while i < l
    # Check if we have nested arrays
    if @[i] instanceof Array and array[i] instanceof Array
      # recurse into the nested arrays
      if !@[i].equals(array[i])
        return false
    else if @[i] != array[i]
      # Warning - two different object instances will never be equal: {x:20} != {x:20}
      return false
    i++
  true

Array::diff = (array) ->
    # if the other array is a falsy value, return
    if !array
        return "!array"
    # compare lengths - can save a lot of time 
    if @length != array.length
        return "@length != array.length"
    i = 0
    l = @length
    returnArray = []
    while i < l
        returnArray[i] =  @[i] - array[i]
    return returnArray

between = (a, b) ->
  if a > b
    this >= b and this <= a
  else
    this >= a and this <= b

Number::between = between
String::between = between
Date::between = between
##################################### END IF OVERRIDES #######################################

generateUUID = ->
    #console.debug "generateUUID ***"
    d = (new Date).getTime()
    uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) ->
      r = (d + Math.random() * 16) % 16 | 0
      d = Math.floor(d / 16)
      (if c == 'x' then r else r & 0x3 | 0x8).toString 16
    )
    return uuid
sigmoid = (t) ->
    exp = 1/(1+Math.exp(-t))
    #console.debug "sigmoid (#{t})= #{exp}"
    return exp
# put energy to motor X
move: (direction)->
    # syntheticaly update my state
    @state.energy-2
    console.log "move ***"
    if direction is undefined
        x = Math.floor(Math.random())
        y = Math.floor(Math.random())
        z = Math.floor(Math.random())
        direction = [x,y,z]
    return yes
# put energy to voice (textoutput)
say: (text)->
    # syntheticaly update my state
    @state.energy-2
    console.log "say ***"
    # we say something random, that will reduce energy
    possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    if text is undefined
        text = possible.charAt Math.floor(Math.random() * possible.length)
    console.info text
    return yes
# graph options
# options = series:
#     lines: show: no
#     points:
#         radius: 3
#         show: true

class Brain
    constructor: ->
        @id = generateUUID()
        # The trust in myself and the initial value for trust in my memes/concepts
        @trust = 200
        @maxTrust = 1
        @minTrust = 0.000000000001
        @battery = 100              # My energylevel at birth
        @pulse = 400                # The idletime in ms before the next "beat" is processed
        # Initialize state value limits
        @stateMax = []
        @stateMin = []
        @birthdate=(new Date).getTime()/timeDivider
        @stateMin[1]=1              # Define the lowest energylevel
        # Initializing Memories of the Brain
        @memState = []              # Saving the states over time so we can predict
        @memOry = []                # Longterm Memory containing Memes (What was done, how was the state)
        @memPlan = []               # Future plan containing Memes (What to do, what state to expect)
        @currentState = @getState() # get all the input values and put them into an array
        # - - - - - - - - - - - - - - INCEPTION - - - - - - - - - - - - - - - - - - - - - -
        # This meme means EATING! Since we don't have a environment yet that could transfer
        # energy to us
        tempMeme = new Meme @, "origin.battery+=1; console.log('Ich esse!');", @currentState
        @memOry.push tempMeme
        ##---------------------------------------------------------------------------------
        # This meme means MEDITATION!
        tempMeme = new Meme @, "Me.updateCurrentState();", @currentState
        # Plan for life
        @memPlan.push tempMeme
        # initialise memState
        @updateCurrentState()
        @updateCurrentState()
        @updateCurrentState()
        # first heartbeat
        @conciousness = setTimeout @live, @pulse

    getState: =>
        returnState = []
        state = []
        currenttime=(new Date).getTime()/timeDivider
        # We measure time from birth @stateMin[0]
        currenttime=currenttime-@birthdate
        state.push currenttime
        state.push @battery
        #state.push @battery/2
        state.push math.random(0,100)
        state.push 55
        bias = 0.5
        return state

    gaussianElimination = (a, o) ->
        i = 0
        j = 0
        k = 0
        maxrow = 0
        tmp = 0
        n = a.length - 1
        x = new Array(o)
        i = 0
        while i < n
            maxrow = i
            j = i + 1
            while j < n
                if Math.abs(a[i][j]) > Math.abs(a[i][maxrow])
                    maxrow = j
                j++
                k = i
            while k < n + 1
                tmp = a[k][i]
                a[k][i] = a[k][maxrow]
                a[k][maxrow] = tmp
                k++
                j = i + 1
            while j < n
                k = n
                while k >= i
                    a[k][j] -= a[k][i] * a[i][j] / a[i][i]
                    k--
                j++
            i++
        j = n - 1
        while j >= 0
            tmp = 0
            k = j + 1
            while k < n
                tmp += a[k][j] * x[k]
                k++
            x[j] = (a[n][j] - tmp) / a[j][j]
            j--
        x

    methods = 
        linear: (data) ->
            sum = [0,0,0,0,0]
            n = 0
            results = []
            N = 0
            #the actual number of x,y points participating in the regression (excludes forecasted points, i.e., those having a null y-coordinate). 
            while n < data.length
                if data[n][1]
                    sum[0] += data[n][0]
                    sum[1] += data[n][1]
                    sum[2] += data[n][0] * data[n][0]
                    sum[3] += data[n][0] * data[n][1]
                    sum[4] += data[n][1] * data[n][1]
                    N++
                n++
            # var gradient = (n * sum[3] - sum[0] * sum[1]) / (n * sum[2] - sum[0] * sum[0]);
            # var intercept = (sum[1] / n) - (gradient * sum[0]) / n;
            # var correlation = (n * sum[3] - sum[0] * sum[1]) / Math.sqrt((n * sum[2] - sum[0] * sum[0]) * (n * sum[4] - sum[1] * sum[1]));
            gradient = (N * sum[3] - sum[0] * sum[1]) / (N * sum[2] - sum[0] * sum[0])
            intercept = sum[1] / N - (gradient * sum[0] / N)
            i = 0
            len = data.length
            while i < len
                coordinate = [
                    data[i][0]
                    data[i][0] * gradient + intercept
                ]
                #this plots all data points (including forcasted points)
                results.push coordinate
                i++
            string = 'y = ' + Math.round(gradient * 100) / 100 + 'x + ' + Math.round(intercept * 100) / 100
            # var string = 'y = ' + gradient + 'x + ' + intercept;   //actual equation
            return {
                equation: [
                  gradient
                  intercept
                ]
                points: results
                string: string
            }
        exponential: (data) ->
            sum = [0,0,0,0,0,0]
            n = 0
            results = []
            len = data.length
            while n < len
                if data[n][1] != null
                    sum[0] += data[n][0]
                    sum[1] += data[n][1]
                    sum[2] += data[n][0] * data[n][0] * data[n][1]
                    sum[3] += data[n][1] * Math.log(data[n][1])
                    sum[4] += data[n][0] * data[n][1] * Math.log(data[n][1])
                    sum[5] += data[n][0] * data[n][1]
                n++
            denominator = sum[1] * sum[2] - sum[5] * sum[5]
            A = Math.E ** ((sum[2] * sum[3] - sum[5] * sum[4]) / denominator)
            B = (sum[1] * sum[4] - sum[5] * sum[3]) / denominator
            i = 0
            len = data.length
            while i < len
                coordinate = [
                    data[i][0]
                    A * Math.E ** (B * data[i][0])
                ]
                results.push coordinate
                i++
            string = 'y = ' + Math.round(A * 100) / 100 + 'e^(' + Math.round(B * 100) / 100 + 'x)'
            return {
                equation: [
                    A
                    B
                ]
                points: results
                string: string
            }
        logarithmic: (data) ->
            sum = [0,0,0,0]
            n = 0
            results = []
            len = data.length
            while n < len
                if data[n][1] != null
                    sum[0] += Math.log(data[n][0])
                    sum[1] += data[n][1] * Math.log(data[n][0])
                    sum[2] += data[n][1]
                    sum[3] += Math.log(data[n][0]) ** 2
                n++
            B = (n * sum[1] - sum[2] * sum[0]) / (n * sum[3] - sum[0] * sum[0])
            A = (sum[2] - B * sum[0]) / n
            i = 0
            len = data.length
            while i < len
                coordinate = [
                    data[i][0]
                    A + B * Math.log(data[i][0])
                ]
                results.push coordinate
                i++
            string = 'y = ' + Math.round(A * 100) / 100 + ' + ' + Math.round(B * 100) / 100 + ' ln(x)'
            return {
                equation: [
                    A
                    B
                ]
                points: results
                string: string
            }
        power: (data) ->
            sum = [0,0,0,0]
            n = 0
            results = []
            len = data.length
            while n < len
                if data[n][1] != null
                    sum[0] += Math.log(data[n][0])
                    sum[1] += Math.log(data[n][1]) * Math.log(data[n][0])
                    sum[2] += Math.log(data[n][1])
                    sum[3] += Math.log(data[n][0]) ** 2
                n++
            B = (n * sum[1] - sum[2] * sum[0]) / (n * sum[3] - sum[0] * sum[0])
            A = Math.E ** ((sum[2] - B * sum[0]) / n)
            i = 0
            len = data.length
            while i < len
                coordinate = [
                    data[i][0]
                    A * data[i][0] ** B
                ]
                results.push coordinate
                i++
            string = 'y = ' + Math.round(A * 100) / 100 + 'x^' + Math.round(B * 100) / 100
            return {
                equation: [
                    A
                    B
                ]
                points: results
                string: string
            }
        polynomial: (data, order) ->
            if typeof order == 'undefined'
                order = 3
            lhs = []
            rhs = []
            results = []
            a = 0
            b = 0
            i = 0
            k = order + 1
            while i < k
                l = 0
                len = data.length
                while l < len
                    if data[l][1] != null
                        a += data[l][0] ** i * data[l][1]
                    l++
                lhs.push(a)
                a = 0
                c = []
                j = 0
                while j < k
                    l = 0
                    len = data.length
                    while l < len
                        if data[l][1] != null
                            b += data[l][0] ** (i + j)
                        l++
                    c.push(b)
                    b = 0
                    j++
                rhs.push c
                i++
            rhs.push lhs
            equation = gaussianElimination(rhs, k)
            while i < len
                answer = 0
                w = 0
                while w < equation.length
                    answer += equation[w] * data[i][0] ** w
                    w++
                results.push [
                    data[i][0]
                    answer
                ]
                i++
            string = ''
            while i >= 0
                xTimes = Math.round(equation[i] * 100) / 100
                if isNaN xTimes
                    xTimes = 0
                if i > 1
                    string += xTimes + '*x^' + i + ' + '
                else if i == 1
                    string += xTimes + '*x' + ' + '
                else
                    string += xTimes
                i--
            return {
                equation: equation
                points: results
                string: string
            }
        lastvalue: (data) ->
            results = []
            lastvalue = null
            i = 0
            while i < data.length
                if data[i][1]
                    lastvalue = data[i][1]
                    results.push [
                        data[i][0]
                        data[i][1]
                    ]
                else
                    results.push [
                        data[i][0]
                        lastvalue
                    ]
                i++
            return {
                equation: [ lastvalue ]
                points: results
                string: '' + lastvalue
            }

    regression = (method, data, order) ->
        if typeof method == 'string'
            return methods[method](data, order)
        return

    die: (age)->
        console.error "#{Me.id} DIED in the age of #{age}days !!!"

    checkState: (@currentState, expectedState) ->
        if not expectedState?
            return 0
        diff = 0
        trust = 0
        for value in [0...@currentState.length]
            tolerance = @currentState[value]/100
            diff = sigmoid((@currentState[value]-expectedState[value])/expectedState[value])
            if diff-tolerance < 0.51 and diff+tolerance > 0.49
                #console.info "expected value! #{diff} #{tolerance}"
                trust += diff
            else
                #console.error "unexpected value! #{diff} #{tolerance}"
                trust -= diff
        #console.debug "trust: #{trust/@currentState.length}"
        return trust/@currentState.length

    ttl:(memState, StateValueIndex) ->
        # Predict the time when value i exceeds
        #types = ["linear","logarithmic","power","polynomial","exponential","lastvalue"]
        #types = ["polynomial","linear","lastvalue"]
        types = ["linear","lastvalue"]
        typeIndex=0
        while isNaN(predictedUnderload)
            type=types[typeIndex]
            predictionLowLimit = @predict "time", @stateMin[StateValueIndex]*0.95, type, StateValueIndex, memState
            pLLpoints=predictionLowLimit[1]
            pLLLastpoint=pLLpoints[pLLpoints.length-1]
            predictedUnderload = pLLLastpoint[1]-memState[memState.length-1][0]
            typeIndex++
            if typeIndex > types.length then break
        #console.log "predictedUnderload (#{types[typeIndex-1]}): ",predictedUnderload
        
        typeIndex=0
        while isNaN(predictedOverload)
            type=types[typeIndex]
            predictionUpLimit = @predict "time", @stateMax[StateValueIndex]*1.05, type, StateValueIndex, memState
            pULpoints=predictionUpLimit[1]
            pULLastpoint=pULpoints[pULpoints.length-1]
            predictedOverload = pULLastpoint[1]-memState[memState.length-1][0]
            typeIndex++
            if typeIndex > types.length then break
        #console.log "predictedOverload (#{types[typeIndex-1]}): ",predictedOverload

        # draw the prediction on the canvas
        divdings='#canvas'+StateValueIndex
        $.plot($(divdings.toString()), [
            {data:predictionUpLimit[0],lines:{show:yes},points:{show:no}}
            {data:predictionLowLimit[0],lines:{show:yes},points:{show:no}}
            {data:pLLpoints,lines:{show:no},points:{show:yes,symbol: "square",radius:3}}
            {data:pULpoints,lines:{show:no},points:{show:yes,symbol: "diamond",radius:2}}
        ]);

        
        if predictedOverload < 0
            predictedOverload=Infinity
        if predictedUnderload < 0
            predictedUnderload=Infinity
        return [predictedUnderload,predictedOverload]

    # regularize the values of "state"
    # using the calculated mean values of memState
    regularize: (state,memState,meanScaled)->
        bias = 0.0000001
        returnState=[]
        tmemState=math.transpose(memState)
        for i in [0...state.length]
            range=@stateMax[i]-@stateMin[i]
            if meanScaled?
                mean=math.mean(tmemState[i])+bias
            else
                mean=0
            part=state[i]-mean
            returnState.push(math.round(part/range,5))
        return returnState

    predict: (type, value, regressionMethod, index, dataset) =>

        # regularize the whole dataset "inputData"
        regularized=[]
        for state in dataset
            regularizedState = @regularize(state,dataset) 
            regularized.push(regularizedState)

        inputData=[]
        tdatasetReg = math.transpose(regularized)
        tdataset = math.transpose(dataset)
        if type is "value"
            # predict the value
            inputData.push tdataset[0]
            inputData.push tdataset[index]
        else
            # predict the time
            inputData.push tdataset[index]
            inputData.push tdataset[0]

        inputData = math.transpose(inputData)
        #console.debug "inputData:",inputData
        # Artificial state to predict
        predictState = []
        predictState.push value
        predictState.push null
        # return the last record if we have not enough data to create a prediction
        if inputData.length < 2
            console.warn "To young to predict"
            return [inputData,dataset[dataset.length-1]]
        # add the partially empty state
        inputData.push predictState
        prediction = regression(regressionMethod, inputData)
        if prediction?
            outputData = prediction.points
        else
            console.warn "PREDICTION FAILED!"
            outputData = inputData
        return [inputData,outputData]

    updateCurrentState: =>
        @currentState = @getState()
        @memState.push @currentState

    updateLimits: =>
        bias = 0.0000001
        # update maximum and minimum values
        for i in [0...@currentState.length]
            if not @stateMax[i]?
               @stateMax[i] = @currentState[i]+bias
            if not @stateMin[i]?
               @stateMin[i] = @currentState[i]-bias
            if @currentState[i] > @stateMax[i]
                @stateMax[i] = @currentState[i]
            if @currentState[i] < @stateMin[i]
                @stateMin[i] = @currentState[i]


    live: =>
        # How much the state may differ from prediction
        #------------------ Run the meme
        startTime = (new Date).getTime()/timeDivider
        meme = @memPlan.shift()
        if not meme?
            return
        else
            console.log "----------------------------------------------------------------------"
            #console.debug meme
        # run the planed task
        console.log "Run Task: ",meme.task
        meme.run()
        expectationError = @checkState @currentState, meme.expectedState
        meme.setTrust expectationError
        console.log "#{Math.round((meme.trust/@maxTrust)*100)}% matched expected! #{expectationError} "
        
        #---------- Predict the values for the next heartbeat -----
        nextBeat = (@currentState[0])+(@pulse/timeDivider)
        nextBeatState=[]
        nextBeatState[0]=nextBeat
        for i in [1...@currentState.length]
            nextBeatValue = @predict "value", nextBeat, "linear", i, @memState
            nBVpoints=nextBeatValue[1]
            nBVlastPoint=nBVpoints[nBVpoints.length-1]
            nextBeatState.push nBVlastPoint[1]

        updatedMeme = new Meme meme, meme.task, @currentState
        updatedMeme.duration = meme.duration
        updatedMeme.expectedState = nextBeatState
        @memOry.push updatedMeme
        @memPlan.push updatedMeme

        #----------- Predict if we hit a limit -------------------
        #----------- I want to hit no limit ----------------------
        # comparing, predicting, planing, and optimizing
        console.log "currentState:", @currentState
        console.log "nextBeatState:", nextBeatState   
        # Find out what i want
        wantedDiff = []
        # I want infinitly...
        timelefts  = [Infinity]
        # ...to not reach a limit!
        # But if i predicted reaching a limit
        # then i want to regulate
        for i in [1...@currentState.length]
            timeleft = @ttl @memState, i
            timeleft = math.min(timeleft)
            if timeleft < Infinity and timeleft > 0
                timelefts.push timeleft
                diff = nextBeatState[i]-@currentState[i]
                wantedDiff.push -diff
            else
                wantedDiff.push 0
        wantedDiff.unshift math.min(timelefts)
        console.log "I want: ",wantedDiff
        #@findDiff wantedDiff
        #regulationMeme = new Meme meme, meme.task, @currentState
        # @memPlan.push regulationMeme

        #-------------------- updating my shit ---------------------
        # Adjust memState.length in respect of the pulse
        # so i have nearly everytime the same timespan of data for prediction
        while @memState.length > 5*(12-math.sqrt(@pulse)/3)
            @memState.shift()

        # Update my poise
        sumTrust=0
        for meme in @memOry
            sumTrust += meme.trust
        @trust = sumTrust/@memOry.length
        
        # Update my limits
        @updateLimits()

        # XXX no computing if battery is empty 
        if @battery > 0
            @conciousness = setTimeout @live, @pulse
        else
            console.error "DEAD!"

        endTime = (new Date).getTime()/timeDivider
        console.log "Beat Duration: #{endTime-startTime}"
        #-----------------------------------------------------------

    
# A thought or cascade of thoughts or concept
# @trust:  I have a certain trust of the outcome ...
# @origin: I know where this thought came about ...
# @task:   Thinking is doing, a task is the smallest thing i can DO, the output!
#          What i can do is defined by my "bodymuscles"
# @duration: It's the duration the task took last time 
# @expectedState: I expect a outcome of this which is a predicted(or guessed) state
# @time: timestamp for the meme (and the state)
class Meme 
    constructor: (origin,task,expectedState) ->
        @id = generateUUID()
        @trust = origin.trust
        @maxTrust = origin.maxTrust
        @minTrust = origin.minTrust
        @origin = origin.id
        @task = task
        @duration = undefined
        @expectedState = expectedState
        @time = (new Date).getTime()/timeDivider
    
    run: =>
        # start Timemeasurement to find out duration of the task
        startTime = (new Date).getTime()/timeDivider
        # run the task
        # for i in meme.task
        eval(@task)
        endTime = (new Date).getTime()/timeDivider
        @duration = endTime-startTime
        console.log "Task Duration: #{@duration}"

    setTrust: (addtrust) =>
        @trust = 2*(addtrust*@maxTrust)
        if @trust <= @minTrust 
            @trust = @minTrust
        if @trust > @maxTrust 
            @trust = @maxTrust
 

######################################## GENE ###################################################

# timeDivider is necessary because predicting in ms-resolution is hard
timeDivider=1000
# Me is born
Me = new Brain


##---------------------------------------------------------------------------------
##           THIS IS FAKESTUFF NEEDED AS LONG AS THIS IS SOFTWARE
##---------------------------------------------------------------------------------

######################################## ENVIRONMENT ############################################
lowerEnergy= ->
    Me.battery += math.random(-13, 10)
    # simulate physical boundaries of the battery
    if Me.battery>254
        Me.battery=254
    if Me.battery<0
        Me.battery=0

# Entropie
setInterval lowerEnergy, 1000

cutColumn = (matrix,index) ->
    column = matrix.subset(math.index([0, matrix._size[0]], index))
    if index > 0
        leftMatrix = matrix.subset(math.index([0, matrix._size[0]], [0,index-1]))
    if index < matrix._size[1]
        rightMatrix = matrix.subset(math.index([0, matrix._size[0]], [index+1, matrix._size[1]]))

    if not leftMatrix?
        returnMatrix=rightMatrix
    if not rightMatrix?
        returnMatrix=leftMatrix
    if leftMatrix? and rightMatrix?
        returnMatrix = math.concat leftMatrix,rightMatrix
    return [returnMatrix,column]

getRow = (matrix,index) ->
    return matrix.subset(math.index(index, [0, matrix._size[1]]))

###
Normal Equation
===============
PRO:
----
no features scaling needed!
fast on small matrices

CON:
----
slow when a lot of features
    computing inverse is cubical related to matrix size
    10000 x 10000 -> gradient descent

not working if determinant is zero
    For an n×n matrix, each of the following is equivalent to the condition of the matrix having determinant 0:
    The columns of the matrix are dependent vectors in ℝn
    The rows of the matrix are dependent vectors in ℝn
    The matrix is not invertible.
    The volume of the parallelepiped determined by the column vectors of the matrix is 0.
    The volume of the parallelepiped determined by the row vectors of the matrix is 0.
    The system of homogenous linear equations represented by the matrix has a non-trivial solution.
    The determinant of the linear transformation determined by the matrix is 0.
    The free coefficient in the characteristic polynomial of the matrix is 0.
    Depending on the definition of the determinant you saw, proving each equivalence can be more or less hard.
###

normalequation = (x,y) ->
    # x = math.matrix([
    #     [2104,5,1,45]
    #     [1416,3,2,40]
    #     [1534,3,2,30]
    # ])
    # y = math.matrix([
    #     [460]
    #     [232]
    #     [315]
    # ])
    x =     math.matrix(x)
    xzero = math.ones(x._size[0],1)
    x =     math.concat(xzero,x)
    xt =    math.transpose(x)
    xtxi =  math.inv(math.multiply(xt,x))
    theta = math.multiply(math.multiply(xtxi, xt), y)
    return theta




###

# -------------------------  Maybe Later
 
        # rms = @regularize(nextBeatState,@memState,yes)
        # rmv=rms.slice(0)
        # rmv.shift()

        # adjust the pulse
        #console.log @currentState
        #console.log math.std @currentState
        #console.log math.var @currentState
# -------------------------
# -------------------------

# EFFECTIVE ---------------------------------
# find a point in @memState when energy was raised
# save the found timestamp and the raiseamount
# sort out when the highest raise happened

# If we couldn't find anything
# try something random

# EFFICIENT ---------------------------------
# find a meme with nearly the same timestamp
# save the found meme into an array
# check the trust of this meme

# PREDICT -------------------------------------
# Find out how much time we have before we hit min
# Find out how many cycles that is with the current pulse

# For i in cycles
# plan memes as found in above
# if our selftrust is higher than the memetrust
# PLAN THE MEMES IN A NEW MEME! Not directly in the main @memPlan

Data1:      [0  ,0  ,0  ,0  ,0 ]
Prediction: [0  ,0  ,0  ,0  ,0 ]
Data2:      [-5 ,5  ,0  ,-1 ,1 ]
Prediction: [-15,15 ,0  ,-3 ,3 ]
Data1:      [-5 ,13 ,0  ,-3 ,3 ]
Prediction: [0  ,0  ,0  ,0  ,0 ]

New Prediction = Value * Prediction * Wrongness

Prediction: [*3 ,*3 ,*3 ,*3 ,*3]
Wrongness:  [0  ,0  ,0  ,0  ,0 ]

Raise or lower?

COSTFUNCTION
------------
Diff1: [-5,5,0,-1,1]
Diff2: [10,-2,0,0,0]

Not a Norm!
average of sum of all diffs:
    [-5,5,0,-1,1] = 0/length = 0 NO ERRORS!!! 
    [10,-2,0,0,0]  = 8/5 = 1.6 = Wrongness

L1-Norm:
Used in Regularization called "LASSO"
average of sum of all Abs(diffs):
    [5,5,0,1,1] = 12/length = 2.4
    [10,2,0,0,0]= 12/length = 2.4

L2-Norm:
Used in Regularization called "Ridge Regression"
Squared Error Cost Function
squareroot of sum of all diffs*diffs: 
    [25,25,0,1,1] = sqrt(52) = 7.211
    [100,4,0,0,0] = sqrt(104) = 10.198 

Not a Norm, might produce a negative number:
average of sum of all diffs*diffs: 
    [25,25,0,1,1] = 52/length = 10.4
    [100,4,0,0,0] = 104/length = 20.8 

Regularization is finding the correct formula (*3 or what?) not only the correct weight(wrongness)
For L1 and L2 in combination with Regularization.
High values will increase the Cost.
Whut? -> Being equally wrong on all parameters like [40,40,40,40,40]
would lead to a high Wrongness. But the Wrongness(or weight)
wouldn't be wrong in that case it would be JUST the function (*3)
that should be adjusted. 



Gradient Descent
----------------
Stochastic = random pic ONE dataset
Minibatch  = pic a small subset of the dataset
batch = use all of the dataset

CLustering
----------
K-Means -> You have to know the number of clusters you want to find

Cocktailparty
-------------
Form a block matrix of size m by n, with a copy of matrix A as each element.

A = sum(x.*,1)
m = size(x,1) # the numer of training examples
n = 1

[W,s,v] = 
    svd(
        (
            repmat(A,m,n)
        .*x)
    *x');

svd = http://de.wikipedia.org/wiki/Singul%C3%A4rwertzerlegung
repmat = repeat matrix






repmat <- function(A, m, n = m) {
  if(missing(m))
    stop("Requires at least 2 inputs.")

  if(is.vector(A))
    A <- t(matrix(A))
  
  d <- dim(A)
  nr <- d[1]
  nc <- d[2]
  
  if(length(m) <= 2) {
    m[2] <- ifelse(is.na(m[2]), n, m[2])
    
    if(length(d) > 2) {
      ret <- array(dim = c(nr * m[1], nc * m[2], d[-(1:2)]))
      for(i in 1:d[length(d)]){
        sep <- paste(rep(",", length(d) - 1),  collapse="")
        eval(parse(text = sprintf("ret[%si] <- repmat(A[%si], m[1], m[2])", sep, sep)))
      }
    } else {
      tmpA <- matrix(rep(t(A), m[1]), nrow = nr * m[1], byrow = TRUE)
      return(matrix(rep(tmpA, m[2]), nrow = nr * m[1], ncol = nc * m[2]))
    }
    ret
  } else {
    if(length(d) > 2) 
      stop("Doesn't support these arguments.")
    tmpA <- matrix(rep(t(A), m[1]), nrow = nr * m[1], byrow = TRUE)
    tmpA <- matrix(rep(tmpA, m[2]), nrow = nr * m[1], ncol = nc * m[2])
    array(rep(tmpA, prod(m[-(1:2)])), c(nr * m[1], nc * m[2], m[-(1:2)]))
  }
}




Possible implementation
-----------------------


tendence over multiple values



Do the right thing – effectivity
Do things right – efficiancy
----------------------------

find me tasks that create the needed difference to
the current value ordered by trust, value, usedtime 

- check my values – for value in values!
    - predict transgression time of value
    - if transgression time < infinity
        - find pattern that will prevent value from exceeding
            - find tendence in series of tasks from the past
            - find a usefull diff between two tasks
            - try something random 
        - find pattern that led to exceeding values
        - avoid doing that in future - don't trust that task
        - update relation task <> value

- (check if the found pattern really was the exceeding factor)


Example Problem
---------------
Pain and fear (which leads to avoidance) is just the a exceeded threshold of a predicted duration until a value exceeds...
The trust for the prediction task is bound to our poise (trust in ourself) and the threshold for fear.
If our poise is low then we don't trust our own prediction which leads to fear.

Pain is a causality with a value exceeding, or a threshold of that value exceeding.
Pain is not bound to all our input values. or is it?

Prediction is a thought and therefor not part of a causality so preventing prediction has no effect. Because Prediction is a task that uses no output. Only tasks that uses our output (any form of muscle) are part of the environment and therefor may lead to pain.

There must be a underlying task (which has a fixed trust) that perpetuates prediction.
That is our cells using up our energy to create a output which is matter (even more cells).

Cells constantly using up energy to create matter, is the task with a fixed trust (or at least with no way of avoidance) that will bring the value "energy" in terms of the energy in our body, to exceed which causes a pain we call "hunger".

So doing "nothing" which means avoiding everything will also lead to exceeding values.

Brings up the question what is the purpose of cells creating new matter in form of new cells.
It's a repair procedure. Is the recreation of cells really a part of a subconcious life-expectancy-prediction-process? Then recreation itself would be a subconcious task rooted in a life-expectancy-prediction-process predicting exceeding values? The need to repair myself is originated in the environment destroying me. Destroying my matter. 

So i'd have to have the information how much energy it would take, and which tasks i'd have to run, to recreate myself at the same rate as the environment destroys me.

So the call for a prediction is originated in a task of repairing myself.
And the amount of energy used to repair is determined by the prediction over a certain amount of time.

And how much time that is, or how far into the future i am trying to predict depends on how much time i have left to think about it and that is what i am trying to stretch.
As long as i have a plan of a continous energy refill for the shorter time period, i can calculate the time i have left to make more extensive predictions and find a plan i already have in mind or i try using random series of tasks which result in a longer time period with continous energy refill....a.s.o.





- predict ( lowers energy )
- eat (raises energy )
- avoid task "predict"
- checking value - dead



                            rawinput
                             |   |
                     relations   tendence


         relation of values in space to group and improve


        if the tendence leads to exceeded values then
         find tasks that are related to raw or compressed states
            that have the tendence to regulate the exceeding values

        

        relation of values in time to find a plan






###
