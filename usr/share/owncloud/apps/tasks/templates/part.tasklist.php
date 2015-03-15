<div ng-switch-default>
    <div class="grouped-tasks">
        <ol class="tasks" rel="uncompleted" oc-drop-task>
            <li ng-repeat="(id, task) in tasks | filter:filterTasksByCalendar(task,route.listID) | filter:{'completed':'false'} | filter:route.searchString | orderBy:sortDue | orderBy:'starred':true"
            class="task-item ui-draggable" rel="{{ task.id }}" ng-click="openDetails(task.id)" ng-class="{done: task.completed}" oc-drag-task stop-event="click">
                <div class="task-body">
                    <div class="percentdone" style="width:{{ task.complete }}%; background-color:{{ getTaskColor(task.calendarid) }};"></div>
                    <a class="task-checkbox" name="toggleCompleted" ng-click="toggleCompleted(task.id)" stop-event="click">
                        <span class="icon task-checkbox" ng-class="{'task-checked': task.completed}"></span>
                    </a>
                    <a class="icon task-separator"></a>
                    <a class="task-star" ng-click="toggleStarred(task.id)" stop-event="click">
                        <span class="icon task-star faded" ng-class="{'task-starred': task.starred}"></span>
                    </a>
                    <a class="duedate" ng-class="{overdue: TasksModel.overdue(task.due)}">{{ task.due | dateTaskList }}</a>
                    <div class="title-wrapper"  ng-class="{attachment: task.note!=''}">
                        <span class="title">{{ task.name }}</span>
                        <span class="icon task-attachment"></span>
                    </div>
                </div>
            </li>
        </ol>
        <h2 class="heading-hiddentasks" ng-show="getCount(route.listID,'completed')">
            <span class="icon toggle-completed-tasks" ng-click="toggleHidden()"></span>
            <text ng-click="toggleHidden()">{{ getCountString(route.listID,'completed') }}</text>
        </h2>
        <ol class="completed-tasks" rel="completed" oc-drop-task>
            <li ng-repeat="task in tasks | filter:filterTasksByCalendar(task,route.listID) | filter:{'completed':'true'} | filter:route.searchString | orderBy:'completed_date':true"
            class="task-item" rel="{{ task.id }}" ng-click="openDetails(task.id)"
            ng-class="{done: task.completed}" oc-drag-task stop-event="click">
                <div class="task-body">
                    <div class="percentdone" style="width:{{ task.complete }}%; background-color:{{ getTaskColor(task.calendarid) }};"></div>
                    <a class="task-checkbox" name="toggleCompleted" ng-click="toggleCompleted(task.id)" stop-event="click">
                        <span class="icon task-checkbox" ng-class="{'task-checked': task.completed}"></span>
                    </a>
                    <a class="icon task-separator"></a>
                    <a class="task-star" ng-click="toggleStarred(task.id)" stop-event="click">
                        <span class="icon task-star faded" ng-class="{'task-starred': task.starred}"></span>
                    </a>
                    <a class="duedate" ng-class="{overdue: TasksModel.overdue(task.due)}">{{ task.due | dateTaskList }}</a>
                    <div class="title-wrapper"  ng-class="{attachment: task.note!=''}">
                        <span class="title">{{ task.name }}</span>
                        <span class="icon task-attachment"></span>
                    </div>
                </div>
            </li>
        </ol>
        <div class="loadmore" ng-hide="loadedAll(route.listID)">
            <span ng-click="getCompletedTasks(route.listID)" stop-event="click"> <?php p($l->t('Load remaining completed tasks.')); ?> </span>
        </div>
    </div>
</div>
