PARTICIPANT = {
  v1: {
    description: "The details of an NPQ Participant",
    type: :object,
    required: %i[id type attributes],
    properties: {
      id: {
        "$ref": "#/components/schemas/IDAttribute",
      },
      type: {
        description: "The data type",
        type: :string,
        example: "npq-participant",
        enum: %w[
          npq-participant
        ],
      },
      attributes: {
        properties: {
          participant_id: {
            description: "The unique identifier of this NPQ participant",
            type: :string,
            format: :uuid,
            nullable: false,
            example: "db3a7848-7308-4879-942a-c4a70ced400a",
          },
          full_name: {
            description: "The full name of this NPQ participant",
            type: :string,
            nullable: false,
            example: "Isabelle MacDonald",
          },
          email: {
            description: "The email address registered for this NPQ participant",
            type: :string,
            nullable: false,
            example: "isabelle.macdonald2@some-school.example.com",
          },
          npq_courses: {
            description: "The type of course(s) the participant is enrolled in",
            type: :array,
            items: {
              type: :string,
              nullable: false,
              example: Course::IDENTIFIERS.first,
              enum: Course::IDENTIFIERS,
            },
          },
          funded_places: {
            description: "Information about the funded place(s) the participant is enroled in",
            type: :array,
            items: {
              type: :object,
              required: %i[npq_course funded_place npq_application_id],
              properties: {
                npq_course: {
                  description: "The type of course the participant is enrolled in",
                  type: :string,
                  nullable: false,
                  example: Course::IDENTIFIERS.first,
                  enum: Course::IDENTIFIERS,
                },
                funded_place: {
                  description: "Indicates whether this NPQ participant is funded by DfE",
                  type: :boolean,
                  example: true,
                  nullable: true,
                },
                npq_application_id: {
                  description: "The ID of the NPQ application that was accepted to create this enrolment",
                  type: :string,
                  format: :uuid,
                  nullable: false,
                  example: "db3a7848-7308-4879-942a-c4a70ced400a",
                },
              },
            },
          },
          teacher_reference_number: {
            description: "The Teacher Reference Number (TRN) for this NPQ participant",
            type: :string,
            example: "1234567",
          },
          updated_at: {
            description: "The date the application was last updated",
            type: :string,
            nullable: false,
            format: :"date-time",
            example: "2021-05-31T02:22:32.000Z",
          },
        },
      },
    },
  },
  v2: {
    description: "The details of an NPQ Participant",
    type: :object,
    required: %i[id type attributes],
    properties: {
      id: {
        "$ref": "#/components/schemas/IDAttribute",
      },
      type: {
        description: "The data type",
        type: :string,
        example: "npq-participant",
      },
      attributes: {
        properties: {
          email: {
            description: "The email address registered for this NPQ participant",
            type: :string,
            nullable: false,
            example: "isabelle.macdonald2@some-school.example.com",
          },
          full_name: {
            description: "The full name of this NPQ participant",
            type: :string,
            nullable: false,
            example: "Isabelle MacDonald",
          },
          teacher_reference_number: {
            description: "The Teacher Reference Number (TRN) for this NPQ participant",
            type: :string,
            example: "1234567",
          },
          updated_at: {
            description: "The date the application was last updated",
            type: :string,
            nullable: false,
            format: :"date-time",
            example: "2021-05-31T02:22:32.000Z",
          },
          npq_enrolments: {
            description: "Information about the course(s) the participant is enroled in",
            type: :array,
            items: {
              description: "The details of an NPQ Participant enrolment",
              type: :object,
              required: %i[course_identifier npq_application_id eligible_for_funding training_status targeted_delivery_funding_eligibility],
              properties: {
                course_identifier: {
                  description: "The NPQ course this NPQ application relates to",
                  type: :string,
                  nullable: false,
                  example: Course::IDENTIFIERS.first,
                  enum: Course::IDENTIFIERS,
                },
                schedule_identifier: {
                  description: "The new schedule of the participant",
                  nullable: true,
                  type: :string,
                  example: Schedule::IDENTIFIERS.first,
                  enum: Schedule::IDENTIFIERS,
                },
                cohort: {
                  description: "Indicates which call-off contract would fund this participant's training. 2021 indicates a participant that has started, or will start, their training in the 2021/22 academic year. Once a provider accepts an application, they may change a participant's cohort up until the point of submitting a started declaration.",
                  type: :string,
                  nullable: true,
                  example: "2022",
                },
                eligible_for_funding: {
                  description: "Indicates whether this NPQ participant would be eligible for funding from the DfE",
                  type: :boolean,
                  nullable: false,
                  example: true,
                },
                npq_application_id: {
                  description: "The ID of the NPQ application that was accepted to create this enrolment",
                  type: :string,
                  format: :uuid,
                  nullable: false,
                  example: "db3a7848-7308-4879-942a-c4a70ced400a",
                },
                training_status: {
                  description: "The training status of the NPQ participant",
                  type: :string,
                  enum: Application.training_statuses.keys,
                  example: Application.training_statuses.keys.first,
                },
                school_urn: {
                  description: "The Unique Reference Number (URN) of the school where this NPQ participant is employed",
                  type: :string,
                  nullable: true,
                  example: "106286",
                },
                targeted_delivery_funding_eligibility: {
                  description: "Whether or not this application is eligible for Targeted Delivery Funding uplift",
                  nullable: false,
                  type: :boolean,
                  example: true,
                },
                funded_place: {
                  description: "Indicates whether this NPQ participant is funded by DfE",
                  nullable: true,
                  type: :boolean,
                  example: true,
                },
              },
            },
          },
        },
      },
    },
  },
  v3: {
    description: "The details of an NPQ Participant",
    type: :object,
    required: %i[id type attributes],
    properties: {
      id: {
        "$ref": "#/components/schemas/IDAttribute",
      },
      type: {
        description: "The data type",
        type: :string,
        example: "npq-participant",
      },
      attributes: {
        properties: {
          full_name: {
            description: "The full name of this NPQ participant",
            type: :string,
            nullable: false,
            example: "Isabelle MacDonald",
          },
          teacher_reference_number: {
            description: "The Teacher Reference Number (TRN) for this NPQ participant",
            type: :string,
            example: "1234567",
          },
          updated_at: {
            description: "The date the application was last updated",
            type: :string,
            nullable: false,
            format: :"date-time",
            example: "2021-05-31T02:22:32.000Z",
          },
          npq_enrolments: {
            description: "Information about the course(s) the participant is enroled in",
            type: :array,
            items: {
              description: "The details of an NPQ Participant enrolment",
              type: :object,
              required: %i[email course_identifier npq_application_id eligible_for_funding training_status targeted_delivery_funding_eligibility],
              properties: {
                email: {
                  description: "The email address registered for this NPQ participant",
                  type: :string,
                  nullable: false,
                  example: "isabelle.macdonald2@some-school.example.com",
                },
                course_identifier: {
                  description: "The NPQ course this NPQ application relates to",
                  type: :string,
                  nullable: false,
                  example: Course::IDENTIFIERS.first,
                  enum: Course::IDENTIFIERS,
                },
                schedule_identifier: {
                  description: "The new schedule of the participant",
                  nullable: true,
                  type: :string,
                  example: Schedule::IDENTIFIERS.first,
                  enum: Schedule::IDENTIFIERS,
                },
                cohort: {
                  description: "Indicates which call-off contract would fund this participant's training. 2021 indicates a participant that has started, or will start, their training in the 2021/22 academic year. Once a provider accepts an application, they may change a participant's cohort up until the point of submitting a started declaration.",
                  type: :string,
                  nullable: true,
                  example: "2022",
                },
                eligible_for_funding: {
                  description: "Indicates whether this NPQ participant would be eligible for funding from the DfE",
                  type: :boolean,
                  nullable: false,
                  example: true,
                },
                npq_application_id: {
                  description: "The ID of the NPQ application that was accepted to create this enrolment",
                  type: :string,
                  format: :uuid,
                  nullable: false,
                  example: "db3a7848-7308-4879-942a-c4a70ced400a",
                },
                training_status: {
                  description: "The training status of the NPQ participant",
                  type: :string,
                  enum: Application.training_statuses.keys,
                  example: Application.training_statuses.keys.first,
                },
                school_urn: {
                  description: "The Unique Reference Number (URN) of the school where this NPQ participant is employed",
                  type: :string,
                  nullable: true,
                  example: "106286",
                },
                targeted_delivery_funding_eligibility: {
                  description: "Whether or not this application is eligible for Targeted Delivery Funding uplift",
                  nullable: false,
                  type: :boolean,
                  example: true,
                },
                withdrawal: {
                  description: "The details of an NPQ Participant withdrawal",
                  type: :object,
                  nullable: true,
                  required: %i[reason date],
                  example: nil,
                  properties: {
                    reason: {
                      description: "The reason a participant was withdrawn",
                      type: :string,
                      nullable: false,
                      example: Participants::Withdraw::WITHDRAWAL_REASONS.first,
                      enum: Participants::Withdraw::WITHDRAWAL_REASONS,
                    },
                    date: {
                      description: "The date and time the participant was withdrawn",
                      type: :string,
                      nullable: false,
                      format: :"date-time",
                      example: "2021-05-31T02:22:32.000Z",
                    },
                  },
                },
                deferral: {
                  description: "The details of an NPQ Participant deferral",
                  type: :object,
                  nullable: true,
                  required: %i[reason date],
                  example: nil,
                  properties: {
                    reason: {
                      description: "The reason a participant was deferred",
                      type: :string,
                      nullable: false,
                      example: Participants::Defer::DEFERRAL_REASONS.first,
                      enum: Participants::Defer::DEFERRAL_REASONS,
                    },
                    date: {
                      description: "The date and time the participant was deferred",
                      type: :string,
                      nullable: false,
                      format: :"date-time",
                      example: "2021-05-31T02:22:32.000Z",
                    },
                  },
                },
                created_at: {
                  description: "The date the application was created",
                  type: :string,
                  nullable: false,
                  format: :"date-time",
                  example: "2021-05-31T02:21:32.000Z",
                },
                funded_place: {
                  description: "Indicates whether this NPQ participant is funded by DfE",
                  nullable: true,
                  type: :boolean,
                  example: true,
                },
              },
            },
          },
          participant_id_changes: {
            description: "Information about the Participant ID changes",
            type: :array,
            items: {
              description: "The details of an Participant ID change",
              type: :object,
              required: %i[from_participant_id to_participant_id changed_at],
              properties: {
                from_participant_id: {
                  description: "The unique identifier of the changed from participant training record.",
                  type: :string,
                  format: :uuid,
                  example: "23dd8d66-e11f-4139-9001-86b4f9abcb02",
                },
                to_participant_id: {
                  description: "The unique identifier of the changed to participant training record.",
                  type: :string,
                  format: :uuid,
                  example: "ac3d1243-7308-4879-942a-c4a70ced400a",
                },
                changed_at: {
                  description: "The date and time the Participant ID change",
                  type: :string,
                  format: :"date-time",
                  example: "2021-05-31T02:22:32.000Z",
                },
              },
            },
          },
        },
      },
    },
  },
}.freeze
