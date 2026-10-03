import 'package:capeonn_app/features/auth/data/auth_user.dart';
import 'package:capeonn_app/features/projects/data/project_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 4 - Project Models & Auth Permissions', () {
    test('AuthUser project permission helpers', () {
      final user = AuthUser.fromJson({
        'id': 1,
        'name': 'Manager Mark',
        'email': 'mark@capeonn.test',
        'role': {'slug': 'manager', 'name': 'Manager', 'level': 70},
        'permissions': {
          'projects.view': 'department',
          'projects.manage': 'department',
          'projects.assign': 'department',
        },
      });

      expect(user.canViewProjects, isTrue);
      expect(user.canManageProjects, isTrue);
      expect(user.canAssignProjects, isTrue);

      final employee = AuthUser.fromJson({
        'id': 2,
        'name': 'Dev Dan',
        'email': 'dan@capeonn.test',
        'role': {'slug': 'employee', 'name': 'Employee', 'level': 10},
        'permissions': {
          'projects.view': 'assigned',
        },
      });

      expect(employee.canViewProjects, isTrue);
      expect(employee.canManageProjects, isFalse);
      expect(employee.canAssignProjects, isFalse);
    });

    test('ProjectItem parses correctly with status, priority and dates', () {
      final json = {
        'id': 10,
        'name': 'Mobile App Overhaul',
        'code': 'PRJ-MOB',
        'description': 'Building next-gen mobile experience',
        'client_name': 'Acme Corp',
        'status': 'in_progress',
        'priority': 'urgent',
        'progress': 75,
        'start_date': '2026-09-01',
        'deadline': '2026-10-15',
        'estimated_hours': 160.5,
        'budget': 25000.0,
        'is_overdue': false,
        'days_remaining': 12,
        'department': {'id': 1, 'name': 'Engineering', 'code': 'ENG'},
        'team_lead': {
          'id': 3,
          'name': 'Tara Lead',
          'email': 'tl@capeonn.test',
          'employee_code': 'CAP-0003',
        },
        'created_by': {'id': 2, 'name': 'Meera Manager'},
        'members_count': 5,
        'created_at': '2026-09-01T08:00:00Z',
      };

      final item = ProjectItem.fromJson(json);

      expect(item.id, equals(10));
      expect(item.name, equals('Mobile App Overhaul'));
      expect(item.code, equals('PRJ-MOB'));
      expect(item.status, equals('in_progress'));
      expect(item.statusDisplay, equals('Active'));
      expect(item.priority, equals('urgent'));
      expect(item.priorityDisplay, equals('Urgent'));
      expect(item.progress, equals(75));
      expect(item.estimatedHours, equals(160.5));
      expect(item.budget, equals(25000.0));
      expect(item.isOverdue, isFalse);
      expect(item.daysRemaining, equals(12));
      expect(item.deadlineDisplay, equals('12 days left'));
      expect(item.departmentName, equals('Engineering'));
      expect(item.teamLeadName, equals('Tara Lead'));
      expect(item.membersCount, equals(5));
    });

    test('ProjectMemberItem parses nested roles and assignments', () {
      final json = {
        'id': 101,
        'user_id': 4,
        'name': 'Eli Employee',
        'email': 'eli@capeonn.test',
        'employee_code': 'CAP-0004',
        'project_role': 'Senior Flutter Architect',
        'assigned_at': '2026-09-05T10:30:00Z',
        'department': {'id': 1, 'name': 'Engineering'},
        'designation': {'id': 3, 'name': 'Software Engineer'},
        'role': {'id': 5, 'slug': 'employee', 'name': 'Employee'},
      };

      final member = ProjectMemberItem.fromJson(json);

      expect(member.id, equals(101));
      expect(member.userId, equals(4));
      expect(member.name, equals('Eli Employee'));
      expect(member.projectRole, equals('Senior Flutter Architect'));
      expect(member.departmentName, equals('Engineering'));
      expect(member.designationName, equals('Software Engineer'));
    });

    test('ProjectActivityItem parses audit actions and actor details', () {
      final json = {
        'id': 55,
        'action': 'lead_assigned',
        'description': 'Tara Lead assigned as Team Lead by Meera Manager',
        'metadata': {'team_lead_id': 3, 'team_lead_name': 'Tara Lead'},
        'created_at': '2026-09-01T09:15:00Z',
        'user': {'id': 2, 'name': 'Meera Manager', 'email': 'manager@capeonn.test'},
      };

      final activity = ProjectActivityItem.fromJson(json);

      expect(activity.id, equals(55));
      expect(activity.action, equals('lead_assigned'));
      expect(activity.description, contains('Tara Lead'));
      expect(activity.userName, equals('Meera Manager'));
      expect(activity.metadata?['team_lead_id'], equals(3));
    });

    test('ProjectDashboardStats parses metrics and breakdowns', () {
      final json = {
        'total_projects': 12,
        'in_progress_count': 6,
        'planning_count': 3,
        'on_hold_count': 1,
        'completed_count': 2,
        'cancelled_count': 0,
        'overdue_count': 2,
        'priority_breakdown': {
          'low': 2,
          'medium': 4,
          'high': 4,
          'urgent': 2,
        },
        'upcoming_deadlines': [
          {
            'id': 1,
            'name': 'Client Portal',
            'deadline': '2026-10-10',
            'is_overdue': false,
            'days_remaining': 7,
          }
        ],
        'recent_projects': [],
      };

      final stats = ProjectDashboardStats.fromJson(json);

      expect(stats.totalProjects, equals(12));
      expect(stats.inProgressCount, equals(6));
      expect(stats.overdueCount, equals(2));
      expect(stats.priorityBreakdown['urgent'], equals(2));
      expect(stats.upcomingDeadlines.length, equals(1));
      expect(stats.upcomingDeadlines.first.name, equals('Client Portal'));
    });

    test('PaginatedProjects parses pagination metadata and items', () {
      final json = {
        'data': [
          {
            'id': 1,
            'name': 'Project 1',
            'status': 'in_progress',
          },
          {
            'id': 2,
            'name': 'Project 2',
            'status': 'completed',
          },
        ],
        'meta': {
          'current_page': 1,
          'last_page': 3,
          'per_page': 15,
          'total': 45,
        },
      };

      final paginated = PaginatedProjects.fromJson(json);

      expect(paginated.items.length, equals(2));
      expect(paginated.currentPage, equals(1));
      expect(paginated.lastPage, equals(3));
      expect(paginated.total, equals(45));
      expect(paginated.hasMore, isTrue);
    });

    test('ProjectItem parses review fields: healthLabel, manager, completion request, totalTeamCount', () {
      final json = {
        'id': 20,
        'name': 'API Gateway 2.0',
        'code': 'PRJ-GW',
        'status': 'active',
        'priority': 'high',
        'progress': null,
        'task_metrics_available': false,
        'health_label': 'due_soon',
        'status_changed_at': '2026-10-01T10:00:00Z',
        'status_change_reason': 'Kickoff approved',
        'completion_requested_at': '2026-10-03T09:00:00Z',
        'completion_request_notes': 'All sprints delivered',
        'manager_id': 2,
        'manager': {'id': 2, 'name': 'Meera Manager'},
        'total_team_count': 6,
      };

      final item = ProjectItem.fromJson(json);

      expect(item.id, equals(20));
      expect(item.status, equals('active'));
      expect(item.statusDisplay, equals('Active'));
      expect(item.healthLabel, equals('due_soon'));
      expect(item.healthLabelDisplay, equals('Due Soon'));
      expect(item.managerId, equals(2));
      expect(item.managerName, equals('Meera Manager'));
      expect(item.statusChangeReason, equals('Kickoff approved'));
      expect(item.completionRequestedAt, equals('2026-10-03T09:00:00Z'));
      expect(item.completionRequestNotes, equals('All sprints delivered'));
      expect(item.totalTeamCount, equals(6));
      expect(item.taskMetricsAvailable, isFalse);
      expect(item.progress, isNull);
    });

    test('AddMemberResult parses detail and warnings list', () {
      final json = {
        'detail': {
          'id': 10,
          'name': 'Mobile App Overhaul',
          'status': 'active',
          'priority': 'high',
        },
        'warnings': [
          'User is currently on approved leave (2026-10-01 to 2026-10-10)',
          'User is already assigned to 3 active projects',
        ],
      };

      final result = AddMemberResult.fromJson(json);

      expect(result.detail.project.id, equals(10));
      expect(result.detail.project.name, equals('Mobile App Overhaul'));
      expect(result.warnings.length, equals(2));
      expect(result.warnings.first, contains('approved leave'));
      expect(result.warnings.last, contains('3 active projects'));
    });

    test('ProjectActivityItem parses audit fields: field, oldValue, newValue, reason', () {
      final json = {
        'id': 99,
        'action': 'status_changed',
        'description': 'Status changed from Planned to Active by Meera Manager: Kickoff',
        'field': 'status',
        'old_value': 'planned',
        'new_value': 'active',
        'reason': 'Kickoff meeting complete',
        'created_at': '2026-10-01T10:00:00Z',
        'user': {'id': 2, 'name': 'Meera Manager'},
      };

      final act = ProjectActivityItem.fromJson(json);

      expect(act.id, equals(99));
      expect(act.action, equals('status_changed'));
      expect(act.field, equals('status'));
      expect(act.oldValue, equals('planned'));
      expect(act.newValue, equals('active'));
      expect(act.reason, equals('Kickoff meeting complete'));
      expect(act.userName, equals('Meera Manager'));
    });
  });
}
