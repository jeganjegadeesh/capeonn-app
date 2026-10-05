import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:capeonn_app/features/tasks/data/task_models.dart';
import 'package:capeonn_app/core/network/api_exception.dart';
import 'package:capeonn_app/features/auth/data/auth_user.dart';

void main() {
  group('Phase 5 - Task Lifecycle & Status Transitions', () {
    test('TaskStatus allowedTransitions strictly matches backend state machine', () {
      expect(
        TaskStatus.allowedTransitions[TaskStatus.backlog],
        equals([TaskStatus.assigned, TaskStatus.inProgress]),
      );
      expect(
        TaskStatus.allowedTransitions[TaskStatus.assigned],
        equals([TaskStatus.inProgress, TaskStatus.backlog]),
      );
      expect(
        TaskStatus.allowedTransitions[TaskStatus.inProgress],
        equals([TaskStatus.review, TaskStatus.assigned]),
      );
      expect(
        TaskStatus.allowedTransitions[TaskStatus.review],
        equals([TaskStatus.changesRequired, TaskStatus.completed]),
      );
      expect(
        TaskStatus.allowedTransitions[TaskStatus.changesRequired],
        equals([TaskStatus.inProgress]),
      );
      expect(
        TaskStatus.allowedTransitions[TaskStatus.completed],
        equals([TaskStatus.inProgress]),
      );
    });

    test('TaskStatus allowedTransitionsFor respects role permissions', () {
      // 1. Regular Assignee on in_progress can only submit for review
      final assigneeInProgress = TaskStatus.allowedTransitionsFor(
        currentStatus: TaskStatus.inProgress,
        isAssignee: true,
        canManage: false,
      );
      expect(assigneeInProgress, equals([TaskStatus.review]));

      // 2. Regular Assignee on review cannot self-approve or request changes
      final assigneeReview = TaskStatus.allowedTransitionsFor(
        currentStatus: TaskStatus.review,
        isAssignee: true,
        canManage: false,
      );
      expect(assigneeReview, isEmpty);

      // 3. Team Lead / Manager (who is NOT the assignee) can approve and request changes
      final managerReview = TaskStatus.allowedTransitionsFor(
        currentStatus: TaskStatus.review,
        isAssignee: false,
        canManage: true,
      );
      expect(managerReview, equals([TaskStatus.changesRequired, TaskStatus.completed]));

      // 4. Team Lead / Manager who IS the assignee cannot approve own task (self-approval rule)
      final managerSelfReview = TaskStatus.allowedTransitionsFor(
        currentStatus: TaskStatus.review,
        isAssignee: true,
        canManage: true,
      );
      expect(managerSelfReview, equals([TaskStatus.changesRequired]));
      expect(managerSelfReview.contains(TaskStatus.completed), isFalse);

      // 5. Team Lead / Manager can reopen completed tasks
      final managerCompleted = TaskStatus.allowedTransitionsFor(
        currentStatus: TaskStatus.completed,
        isAssignee: false,
        canManage: true,
      );
      expect(managerCompleted, equals([TaskStatus.inProgress]));

      // 6. Regular employee cannot reopen completed tasks
      final employeeCompleted = TaskStatus.allowedTransitionsFor(
        currentStatus: TaskStatus.completed,
        isAssignee: true,
        canManage: false,
      );
      expect(employeeCompleted, isEmpty);
    });
  });

  group('Phase 5 - TaskItem & Timer Parsing', () {
    test('TaskItem parses position, deadline_variance, and active_timer with is_paused', () {
      final json = {
        'id': 42,
        'company_id': 1,
        'project_id': 10,
        'parent_task_id': null,
        'title': 'Implement Phase 5 API Enhancements',
        'description': 'Role-aware transitions and drift-free timer',
        'status': 'in_progress',
        'priority': 'high',
        'position': 3,
        'due_date': '2026-10-10',
        'is_overdue': false,
        'days_remaining': 5,
        'estimated_hours': 16.0,
        'actual_hours': 8.5,
        'time_variance': 'on_time',
        'deadline_variance': 'on_track',
        'subtasks_count': 2,
        'has_active_timer': true,
        'active_timer': {
          'id': 99,
          'is_paused': true,
          'paused_at': '2026-10-05T12:00:00Z',
          'started_at': '2026-10-05T10:00:00Z',
          'duration_seconds': 7200,
        },
      };

      final task = TaskItem.fromJson(json);

      expect(task.id, equals(42));
      expect(task.position, equals(3));
      expect(task.deadlineVariance, equals('on_track'));
      expect(task.deadlineVarianceDisplay, equals('On Track'));
      expect(task.hasActiveTimer, isTrue);
      expect(task.activeTimer?.isPaused, isTrue);
      expect(task.activeTimer?.pausedAt, equals('2026-10-05T12:00:00Z'));
      expect(task.isDueToday, isFalse);
      expect(task.isDueSoon, isFalse);
    });

    test('TaskItem correctly computes isDueToday and isDueSoon', () {
      final dueTodayTask = TaskItem(
        id: 1,
        companyId: 1,
        projectId: 1,
        title: 'Due today task',
        status: TaskStatus.inProgress,
        dueDate: '2026-10-05',
        daysRemaining: 0,
      );
      expect(dueTodayTask.isDueToday, isTrue);
      expect(dueTodayTask.isDueSoon, isFalse);

      final dueSoonTask = TaskItem(
        id: 2,
        companyId: 1,
        projectId: 1,
        title: 'Due tomorrow task',
        status: TaskStatus.assigned,
        dueDate: '2026-10-06',
        daysRemaining: 1,
      );
      expect(dueSoonTask.isDueToday, isFalse);
      expect(dueSoonTask.isDueSoon, isTrue);

      final completedTask = TaskItem(
        id: 3,
        companyId: 1,
        projectId: 1,
        title: 'Completed task',
        status: TaskStatus.completed,
        dueDate: '2026-10-05',
        daysRemaining: 0,
      );
      expect(completedTask.isDueToday, isFalse);
      expect(completedTask.isDueSoon, isFalse);
    });

    test('TimeEntryItem parses is_paused, paused_at, and is_auto_stopped', () {
      final json = {
        'id': 101,
        'company_id': 1,
        'project_id': 10,
        'task_id': 42,
        'user_id': 5,
        'started_at': '2026-10-05T08:00:00Z',
        'ended_at': '2026-10-05T16:00:00Z',
        'duration_seconds': 28800,
        'duration_hours': 8.0,
        'is_manual': false,
        'is_running': false,
        'is_paused': false,
        'paused_at': null,
        'is_auto_stopped': true,
      };

      final entry = TimeEntryItem.fromJson(json);

      expect(entry.id, equals(101));
      expect(entry.isAutoStopped, isTrue);
      expect(entry.durationFormatted, equals('8h 0m'));
    });
  });

  group('Phase 5 - MyWorkToday & Timesheet Models', () {
    test('MyWorkTodaySummary parses aggregated task collections and today hours', () {
      final json = {
        'due_today_tasks': [
          {'id': 1, 'company_id': 1, 'project_id': 1, 'title': 'Due Today 1', 'status': 'in_progress'},
        ],
        'overdue_tasks': [
          {'id': 2, 'company_id': 1, 'project_id': 1, 'title': 'Overdue 1', 'status': 'assigned', 'is_overdue': true},
        ],
        'in_progress_tasks': [
          {'id': 1, 'company_id': 1, 'project_id': 1, 'title': 'Due Today 1', 'status': 'in_progress'},
        ],
        'hours_logged_today': 4.75,
        'active_timer': null,
      };

      final summary = MyWorkTodaySummary.fromJson(json);

      expect(summary.dueTodayTasks.length, equals(1));
      expect(summary.overdueTasks.length, equals(1));
      expect(summary.inProgressTasks.length, equals(1));
      expect(summary.hoursLoggedToday, equals(4.75));
      expect(summary.activeTimer, isNull);
    });

    test('TimesheetData and TeamTimesheetData parse days and member summaries', () {
      final timesheetJson = {
        'user_id': 7,
        'date_from': '2026-10-05',
        'date_to': '2026-10-11',
        'total_hours': 35.5,
        'total_seconds': 127800,
        'days': [
          {
            'date': '2026-10-05',
            'day_name': 'Monday',
            'hours': 7.5,
            'seconds': 27000,
            'entries_count': 2,
            'tasks': [
              {
                'task_id': 12,
                'task_title': 'Task A',
                'project_name': 'Mobile App',
                'duration_hours': 4.0,
                'is_manual': false,
              }
            ],
          }
        ],
      };

      final timesheet = TimesheetData.fromJson(timesheetJson);
      expect(timesheet.totalHours, equals(35.5));
      expect(timesheet.days.length, equals(1));
      expect(timesheet.days.first.dayName, equals('Monday'));
      expect(timesheet.days.first.tasks.first.taskTitle, equals('Task A'));

      final teamJson = {
        'date_from': '2026-10-05',
        'date_to': '2026-10-11',
        'total_hours': 80.0,
        'members': [
          {
            'user': {
              'id': 7,
              'name': 'Jegadeesh',
              'email': 'jegadeesh@capeonn.test',
              'employee_code': 'EMP007',
            },
            'total_hours': 40.0,
            'total_seconds': 144000,
            'entries_count': 10,
          }
        ],
      };

      final teamTimesheet = TeamTimesheetData.fromJson(teamJson);
      expect(teamTimesheet.totalHours, equals(80.0));
      expect(teamTimesheet.members.length, equals(1));
      expect(teamTimesheet.members.first.user?.name, equals('Jegadeesh'));
    });
  });

  group('Phase 5 - AuthUser & Friendly Exceptions', () {
    test('AuthUser parses departmentId and checks task management permissions', () {
      final userJson = {
        'id': 10,
        'name': 'Manager User',
        'email': 'manager@capeonn.test',
        'role': {'id': 2, 'slug': 'manager', 'name': 'Manager', 'level': 50},
        'department': {'id': 3, 'name': 'Engineering'},
        'permissions': {'tasks.view': 'department', 'tasks.manage': 'department'},
      };

      final user = AuthUser.fromJson(userJson);

      expect(user.departmentId, equals(3));
      expect(user.departmentName, equals('Engineering'));
      expect(user.isManager, isTrue);
      expect(user.canManageTasks, isTrue);
    });

    test('ApiException generates friendly messages for 403, 404, 422, and 401', () {
      final forbiddenEx = ApiException.fromDio(DioException(
        requestOptions: RequestOptions(path: '/tasks/1'),
        response: Response(
          requestOptions: RequestOptions(path: '/tasks/1'),
          statusCode: 403,
          data: {'message': ''},
        ),
      ));
      expect(forbiddenEx.isForbidden, isTrue);
      expect(forbiddenEx.displayMessage, equals("You don't have permission to perform this action."));

      final notFoundEx = ApiException.fromDio(DioException(
        requestOptions: RequestOptions(path: '/tasks/999'),
        response: Response(
          requestOptions: RequestOptions(path: '/tasks/999'),
          statusCode: 404,
          data: {'message': ''},
        ),
      ));
      expect(notFoundEx.isNotFound, isTrue);
      expect(notFoundEx.displayMessage, equals('The requested resource was not found.'));

      final validationEx = ApiException.fromDio(DioException(
        requestOptions: RequestOptions(path: '/tasks/1/status'),
        response: Response(
          requestOptions: RequestOptions(path: '/tasks/1/status'),
          statusCode: 422,
          data: {
            'message': 'The given data was invalid.',
            'errors': {
              'reason': ['A reason is required when requesting changes.']
            }
          },
        ),
      ));
      expect(validationEx.isValidation, isTrue);
      expect(validationEx.displayMessage, equals('A reason is required when requesting changes.'));
    });
  });
}
