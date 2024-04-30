import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

# make box and whisker plots for data over entire chip and bar plots for over one unit
df = pd.read_excel('/Users/tanerkaraaslan/Desktop/Lab Coding Projects/MEA_Analysis/axon_analytics.xls')

#box and whisker for velocities over entire chip
column_name = 'velocity'
df.boxplot(column=column_name)
plt.title("Box and Whisker Plot of AP Velocities Over Entire Chip")
plt.xlabel("All Units")
plt.ylabel('AP Velocities')
plt.show()

#box and whisker plot for branch lengths over entire chip
column_name = 'length'
df.boxplot(column=column_name)
plt.title("Box and Whisker Plot of Branch Lengths Over Entire Chip")
plt.xlabel("All Units")
plt.ylabel('Branch Lengths')
plt.show()


# creating bar plot for Ap velocities over each unit
# create new array which is an array of the arrays of velocities for each unitid
unitID_column = df['unit_ids']
velocity_column = df['velocity']
currentID = 0
velarray = []
index = 0
unique_values_count = df['unit_ids'].nunique()
for i in range(0, unique_values_count):
    velarray.append([])
    for j in range(index+1,len(unitID_column)):
        if unitID_column.loc[j] == currentID:
            velarray[i].append(velocity_column.loc[j-1])
        else:
            velarray[i].append(velocity_column.loc[j-1])
            currentID = unitID_column.loc[j]
            inner_array_lengths = [len(inner_array) for inner_array in velarray]
            size = inner_array_lengths[i]
            index = index + size
            #inputting 0 values to make same length arrays
            if size < 5:
                for zeros in range(size, 5):
                    velarray[i].append(0)
            break


# add last row manually ** need to figure out a way to get this inside the for loop
velarray[i].append(velocity_column.loc[j])
for j in range(0,3):
    velarray[i].append(0)

#separating branch values for velocity
branch1Array = []
for i in velarray:
    branch1Array.append(i[0])

branch2Array = []
for i in velarray:
    branch2Array.append(i[1])

branch3Array = []
for i in velarray:
    branch3Array.append(i[2])

branch4Array = []
for i in velarray:
    branch4Array.append(i[3])

branch5Array = []
for i in velarray:
    branch5Array.append(i[4])

# obtaining each unique unitid and then sorting them in increasing order
unique_IDs = set(unitID_column)
sorted_IDs = sorted(unique_IDs)

# generating the bar plot
myData = {
    'Category': sorted_IDs,
    'Branch1': branch1Array,
    'Branch2': branch2Array,
    'Branch3': branch3Array,
    'Branch4': branch4Array,
    'Branch5': branch5Array,
}


df = pd.DataFrame(myData)

# Set the positions for the bars
positions = range(len(df))


# Set the width of each bar group
bar_width = 0.2
   
# Create the bar plot
plt.bar(positions, df['Branch1'], width=bar_width, label='Branch1')
plt.bar([pos + bar_width for pos in positions], df['Branch2'], width=bar_width, label='Branch2')
plt.bar([pos + 2*bar_width for pos in positions], df['Branch3'], width=bar_width, label='Branch3')
plt.bar([pos + 3*bar_width for pos in positions], df['Branch4'], width=bar_width, label='Branch4')
plt.bar([pos + 4*bar_width for pos in positions], df['Branch5'], width=bar_width, label='Branch5')
# Add more plt.bar() calls for additional sets of bars

# Add labels, title, and legend
plt.xlabel('UnitID')
plt.ylabel('Velocity')
plt.title('Grouped Bar Plot')
plt.xticks([pos + bar_width / 10 for pos in positions], df['Category'])
plt.legend()
plt.tick_params(axis='both', which='major', labelsize=6)
# Show the plot
plt.show()

# creating bar plot for branch lengths over each unit
# redefine df because I redefined it earlier 
df = pd.read_excel('/Users/tanerkaraaslan/Desktop/Lab Coding Projects/MEA_Analysis/axon_analytics.xls')

# create new array which is an array of the arrays of velocities for each unitid
unitID_column = df['unit_ids']
length_column = df['length']
currentID = 0
lenarray = []
index = 0
unique_values_count = df['unit_ids'].nunique()
for i in range(0, unique_values_count):
    lenarray.append([])
    for j in range(index+1,len(unitID_column)):
        if unitID_column.loc[j] == currentID:
            lenarray[i].append(length_column.loc[j-1])
        else:
            lenarray[i].append(length_column.loc[j-1])
            currentID = unitID_column.loc[j]
            inner_array_lengths = [len(inner_array) for inner_array in lenarray]
            size = inner_array_lengths[i]
            index = index + size
            #inputting 0 values to make same length arrays
            if size < 5:
                for zeros in range(size, 5):
                    lenarray[i].append(0)
            break
# add last row manually **need to figure out a way to get this inside the for loop
lenarray[i].append(unitID_column.loc[j])
lenarray[i].append(length_column.loc[j])
for j in range(0,3):
    lenarray[i].append(0)

#separating branch values for length
branch1Array = []
for i in lenarray:
    branch1Array.append(i[0])

branch2Array = []
for i in lenarray:
    branch2Array.append(i[1])

branch3Array = []
for i in lenarray:
    branch3Array.append(i[2])

branch4Array = []
for i in lenarray:
    branch4Array.append(i[3])

branch5Array = []
for i in lenarray:
    branch5Array.append(i[4])

# getting all unique unitids and sorting in increasing order
unique_IDs = set(unitID_column)
sorted_IDs = sorted(unique_IDs)

# making the bar plot
myData = {
    'Category': sorted_IDs,
    'Branch1': branch1Array,
    'Branch2': branch2Array,
    'Branch3': branch3Array,
    'Branch4': branch4Array,
    'Branch5': branch5Array,
}


df = pd.DataFrame(myData)

# Set the positions for the bars
positions = range(len(df))

# Set the width of each bar group
bar_width = 0.2

# Create the bar plot
plt.bar(positions, df['Branch1'], width=bar_width, label='Branch1')
plt.bar([pos + bar_width for pos in positions], df['Branch2'], width=bar_width, label='Branch2')
plt.bar([pos + 2*bar_width for pos in positions], df['Branch3'], width=bar_width, label='Branch3')
plt.bar([pos + 3*bar_width for pos in positions], df['Branch4'], width=bar_width, label='Branch4')
plt.bar([pos + 4*bar_width for pos in positions], df['Branch5'], width=bar_width, label='Branch5')
# Add more plt.bar() calls for additional sets of bars

# Add labels, title, and legend
plt.xlabel('UnitID')
plt.ylabel('Lengths')
plt.title('Grouped Bar Plot')
plt.xticks([pos + bar_width / 10 for pos in positions], df['Category'])
plt.legend()
plt.tick_params(axis='both', which='major', labelsize=6)
# Show the plot
plt.show()


# making box and whisker plots for each neuron for velocity
# need to edit velarray to not include units with just one branch
value_to_remove = 0
for unit in velarray:
    while value_to_remove in unit:
        unit.remove(value_to_remove)

# making list of indices for which units have more than one branch

storedIndex = -1
Newvelarray = []
indexList = []
for unit in velarray:
    storedIndex += 1
    if len(unit)!=1:
          Newvelarray.append(unit)
          indexList.append(storedIndex)

UnitIDs = []
for index in indexList:
    UnitIDs.append(sorted_IDs[index])

# dictionary for unitid values to be used for x ticks
unitidValues = {
    'UnitIDs': UnitIDs
}

df = pd.DataFrame(unitidValues)
ticks = range(len(UnitIDs))

# Function to annotate box plots
''
def annotate_boxplot(data, xpos, offset):
    min_val = np.min(data)
    max_val = np.max(data)
    q1 = np.percentile(data, 25)
    q3 = np.percentile(data, 75)
    median = np.median(data)
    #plt.text(xpos, min_val - offset, f'Min: {min_val:.2f}', verticalalignment='bottom', horizontalalignment='right', fontsize=4)
    #plt.text(xpos, max_val + offset, f'Max: {max_val:.2f}', verticalalignment='top', horizontalalignment='right', fontsize=4)
    #plt.text(xpos, q1 - offset, f'Q1: {q1:.2f}', verticalalignment='bottom', horizontalalignment='right', fontsize=4)
    #plt.text(xpos, q3 + offset, f'Q3: {q3:.2f}', verticalalignment='top', horizontalalignment='right', fontsize=4)
    #plt.text(xpos, median + offset, f'Median: {median:.2f}', verticalalignment='top', horizontalalignment='right', fontsize=4)
    plt.xlabel('UnitID')
    plt.ylabel('Velocities')
    plt.title('AP Velocities of Each Neuron')
    plt.xticks([pos + bar_width / 10 for pos in ticks], df['UnitIDs'] )
    plt.tick_params(axis='both', which='major', labelsize=8)

for i, data in enumerate(Newvelarray, start=1):
    plt.boxplot(data, positions=[i-1])
    annotate_boxplot(data, i, 10)
plt.show() 

# making box and whisker plots for each neuron for length
# need to edit lenarray to not include units with just one branch
value_to_remove = 0
for unit in lenarray:
    while value_to_remove in unit:
        unit.remove(value_to_remove)

# making list of indices for which units have more than one branch

storedIndex = -1
Newlenarray = []
indexList = []
for unit in lenarray:
    storedIndex += 1
    if len(unit)!=1:
          Newlenarray.append(unit)
          indexList.append(storedIndex)

UnitIDs = []
for index in indexList:
    UnitIDs.append(sorted_IDs[index])


# Function to annotate box plots
''
def annotate_boxplot(data, xpos, offset):
    min_val = np.min(data)
    max_val = np.max(data)
    q1 = np.percentile(data, 25)
    q3 = np.percentile(data, 75)
    median = np.median(data)
    #plt.text(xpos, min_val - offset, f'Min: {min_val:.2f}', verticalalignment='bottom', horizontalalignment='right', fontsize=4)
    #plt.text(xpos, max_val + offset, f'Max: {max_val:.2f}', verticalalignment='top', horizontalalignment='right', fontsize=4)
    #plt.text(xpos, q1 - offset, f'Q1: {q1:.2f}', verticalalignment='bottom', horizontalalignment='right', fontsize=4)
    #plt.text(xpos, q3 + offset, f'Q3: {q3:.2f}', verticalalignment='top', horizontalalignment='right', fontsize=4)
    #plt.text(xpos, median + offset, f'Median: {median:.2f}', verticalalignment='top', horizontalalignment='right', fontsize=4)
    plt.xlabel('UnitID')
    plt.ylabel('Lengths')
    plt.title('Branch Lengths of Each Neuron')
    plt.xticks([pos + bar_width / 10 for pos in ticks], df['UnitIDs'] )
    plt.tick_params(axis='both', which='major', labelsize=8)

for i, data in enumerate(Newlenarray, start=1):
    plt.boxplot(data, positions=[i-1])
    annotate_boxplot(data, i, 10)
plt.show() 






