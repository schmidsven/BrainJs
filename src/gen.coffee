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

class Brain
    constructor: ->
        @trust = 200
        @id = generateUUID()
        @pulse = 300 #200ms average human eyemovementupdate
        @conciousness = setTimeout @live, @pulse
        @stateMax = []
        @stateMin = []
        @stateMin[1]=1
        # Initializing Memories of the Brain
        @memState = [] # Awareness (Saving the state over a reduced time)
        @memOry = []   # Longterm Memory containing Memes (What was done, how was the state)
        @memPlan = []  # Future plan containing Memes (What to do, what state to expect)
        @currentState = @getState()
        # - - - - - - - - - - - - - - INCEPTION - - - - - - - - - - - - - - - - - - - - - -
        # This meme means EATING! Since we don't have a environment yet that could transfer
        # energy to us
        tempMeme = new Meme @, "nowEnergy+=1; console.log('Ich esse!');", @currentState
        @memOry.push tempMeme
        ##---------------------------------------------------------------------------------

        # This meme means MEDITATION!
        tempMeme = new Meme @, "Me.updateCurrentState();", @currentState
        # Plan for life
        @memPlan.push tempMeme

        @options = series:
            lines: show: true
            points:
                radius: 2
                show: true
    getState: =>
        returnState = []
        state = []
        time=(new Date).getTime()/timeDivider
        state.push time
        if not window.nowEnergy?
            window.nowEnergy=unit
        state.push window.nowEnergy
        for i in [0...state.length]
            if not @stateMax[i]?
               @stateMax[i] = state[i] 
            if not @stateMin[i]?
               @stateMin[i] = state[i] 
            if state[i] > @stateMax[i]
                @stateMax[i] = state[i]
            if state[i] < @stateMin[i]
                @stateMin[i] = state[i]
            if i is 0
                returnState[i] = (@stateMax[i]-@stateMin[i])
            else
                returnState[i] = (state[i]*@stateMin[i]) / (@stateMax[i]*@stateMin[i])
            #returnState[i] = sigmoid returnState[i]
        return returnState
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
                order = 2
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
    predict: (inputData, predictState, regressionMethod, canvasDiv) =>
        if inputData.length < 2
            return inputData
        inputData.push predictState
        linear = regression(regressionMethod, inputData)
        inputData.pop()
        if linear?
            outputData = linear.points
            $.plot($(canvasDiv), [
                {data:inputData,label:"matrix#{canvasDiv}"}
                {data:outputData,label:"linear#{canvasDiv}"}
            ], @options);

        else
            console.warning "PREDICTION FAILED!"
            outputData = inputData
        return outputData

    updateCurrentState: =>
        @currentState = @getState()
        @memState.push @currentState

    live: =>
        # How much the state may differ from prediction
        #------------------ Run the meme
        meme = @memPlan.shift()
        if not meme?
            return
        else
            console.log "----------------------------------------------------------------------"
            #console.debug meme
        # run the planed task
        meme.run()
        expectationError = @checkState @currentState, meme.expectedState
        meme.setTrust expectationError
        console.log "#{Math.round((meme.trust/max)*100)}% matched expected! #{expectationError} "
        
        # Predict a value at a given time
        predictState = []
        predictState.push @stateMax[0]-@stateMin[0]+@pulse/timeDivider
        predictState.push null
        points = @predict @memState, predictState, 'linear', '#canvas1'
        predictedState = points[points.length-1]
        canvasDiv='#placeholder'
        
        # Predict a time for a given value
        predictState = []
        predictState.push 0
        predictState.push null
        predictionMatrix = math.transpose(@memState)
        predictionArray = predictionMatrix[0]
        predictionMatrix[0] = predictionMatrix[1]
        predictionMatrix[1] = predictionArray
        predictionMatrix = math.transpose(predictionMatrix)
        predictedTime = @predict predictionMatrix, predictState, 'linear', '#canvas2'
     
        #------------------ save as a new meme in memory (experience)
        updatedMeme = new Meme meme, meme.task, @currentState
        updatedMeme.duration = meme.duration
        @memOry.push updatedMeme

        #------------------ What to do next ???
        # comparing, predicting, planing, and optimizing

        idleTime = (@pulse/timeDivider)-meme.duration

        valuesExceeding = no        
        for i in [1...@currentState.length]
            #########################################

            if predictedState[i] < 0
                valuesExceeding = yes
                console.log "#{i}: sinking...dead in #{@pulse} ms "

                #foundMemes.push findInMemory i, -tendenceState[i]
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

            if predictedState[i] > 1
                valuesExceeding = yes
                console.log "#{i}: raising...dead in #{@pulse} ms "

        if not valuesExceeding
            chilloutTime = predictedState[0]-@currentState[0]
            #@predict(@memState, @pulse/timeDivider)
            # predictionMeme = new Meme meme, meme.task, @currentState
            # @memPlan.push predictionMeme

        # Adjust the precision of prediction depending on
        # the trust of the outcome of this memes task.
        # Higher trust = less data in @memState = faster prediction
        #console.debug "Drop it when it's #{@memState.length} > #{((unit+1-meme.trust)*@trust)*3}"
        while @memState.length > ((unit+1-meme.trust)*@trust)*9
            @memState.shift()


        updatedMeme.expectedState = predictedState
        @memPlan.push updatedMeme

        sumTrust=0
        for meme in @memOry
            sumTrust += meme.trust
        @trust = (sumTrust/@memOry.length)/unit

        # adjust the pulse
        #console.log @currentState
        #console.log math.std @currentState
        #console.log math.var @currentState

        if @currentState[1] > min
            @conciousness = setTimeout @live, @pulse
    
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
        @trust += addtrust*max
        if @trust <= min 
            @trust = min
        if @trust > max 
            @trust = max
 

######################################## GENE ###################################################


# Currently i don't dynamically adjust statevalues
unit = 254
timeDivider=100
# Currently i have no percentage or some battery i can read out so i have to set
# maximum and minimum values and the value at birth
max = unit
min = 0.000000000001
nowEnergy = 90

Me = new Brain

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


##---------------------------------------------------------------------------------
##           THIS IS FAKESTUFF NEEDED AS LONG AS THIS IS SOFTWARE
##---------------------------------------------------------------------------------

######################################## ENVIRONMENT ############################################
lowerEnergy= ->
    nowEnergy -= math.random(2, 8)

# Entropie
setInterval lowerEnergy, 1000


##################################### THOUGHTS ##################################################
###

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
