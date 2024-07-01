PARTICIPANT_DECLARATION = {
  v1: {
    description: "The details of a participant declaration",
    type: :object,
    required: %i[id type attributes],
    properties: {
      id: {
        "$ref": "#/components/schemas/IDAttribute",
      },
      type: {
        description: "The data type",
        type: :string,
      },
      attributes: {
        properties: {
          participant_id: {
            description: "The unique identifier of this participant declaration record",
            type: :string,
            format: :uuid,
            nullable: false,
            example: "db3a7848-7308-4879-942a-c4a70ced400a",
          },
          declaration_type: {
            description: "The event declaration type",
            type: :string,
            nullable: false,
            example: "started",
            enum: %w[
              started
              retained-1
              retained-2
              retained-3
              retained-4
              completed
              extended-1
              extended-2
              extended-3
            ],
          },
          declaration_date: {
            description: "The event declaration date",
            type: :string,
            nullable: false,
            example: "2022-04-30",
          },
          course_identifier: {
            description: "The NPQ course this NPQ application relates to",
            type: :string,
            nullable: false,
            example: "npq-leading-teaching",
            enum: %w[
              npq-leading-teaching
              npq-leading-behaviour-culture
              npq-leading-teaching-development
              npq-leading-literacy
              npq-senior-leadership
              npq-headship
              npq-executive-leadership
              npq-early-years-leadership
              npq-additional-support-offer
              npq-early-headship-coaching-offer
              npq-leading-primary-mathematics
              npq-senco
            ],
          },
          eligible_for_payment: {
            description: "[Deprecated - use state instead] Indicates whether this declaration would be eligible for funding from the DfE",
            type: :boolean,
            nullable: true,
            example: true,
          },
          voided: {
            description: "[Deprecated - use state instead] Indicates whether this declaration has been voided",
            type: :boolean,
            nullable: true,
            example: true,
          },
          state: {
            description: "Indicates the state of this payment declaration",
            type: :string,
            nullable: false,
            example: "submitted",
            enum: %w[
              submitted
              eligible
              payable
              paid
              voided
              ineligible
              awaiting-clawback
              clawed-back
            ],
          },
          updated_at: {
            description: "The date the application was last updated",
            type: :string,
            nullable: false,
            format: :"date-time",
            example: "2021-05-31T02:22:32.000Z",
          },
          has_passed: {
            description: "The date the declaration was last updated",
            type: :string,
            nullable: true,
            example: true,
          },
        },
      },
    },
  },
  v2: {
    description: "The data attributes associated with a participant declaration response",
    type: :object,
    required: %i[id type attributes],
    id: {
      "$ref": "#/components/schemas/IDAttribute",
    },
    type: {
      description: "The data type",
      type: :string,
    },
    attributes: {
      properties: {
        participant_id: {
          description: "The unique id of the participant",
          type: :string,
          format: :uuid,
          example: "db3a7848-7308-4879-942a-c4a70ced400a",
        },
        declaration_type: {
          description: "The event declaration type",
          type: :string,
          enum: %w[
            started
            retained-1
            retained-2
            retained-3
            retained-4
            completed
            extended-1
            extended-2
            extended-3
          ],
          example: "started",
        },
        declaration_date: {
          description: "The event declaration date",
          type: :string,
          format: "date-time",
          example: "2021-05-31T02:21:32.000Z",
        },
        course_identifier: {
          description: "The type of course the participant is enrolled in",
          type: :string,
          enum: %w[
            npq-leading-teaching
            npq-leading-behaviour-culture
            npq-leading-teaching-development
            npq-leading-literacy
            npq-senior-leadership
            npq-headship
            npq-executive-leadership
            npq-early-years-leadership
            npq-additional-support-offer
            npq-early-headship-coaching-offer
            npq-leading-primary-mathematics
          ],
          example: "ecf-induction",
        },
        state: {
          description: "Indicates the state of this payment declaration",
          type: :string,
          enum: %w[
            submitted
            eligible
            payable
            paid
            voided
            ineligible
          ],
          example: "submitted",
        },
        updated_at: {
          description: "The date the declaration was last updated",
          type: :string,
          format: "date-time",
          example: "2021-05-31T02:22:32.000Z",
        },
        has_passed: {
          description: "Whether the participant has failed or passed",
          type: :boolean,
          example: true,
          nullable: true,
        },
      },
    },
  },
  v3: {
    description: "The details of a participant declaration",
    type: :object,
    required: %i[id type attributes],
    properties: {
      id: {
        "$ref": "#/components/schemas/IDAttribute",
      },
      type: {
        description: "The data type",
        type: :string,
      },
      attributes: {
        
      }
  },
}.freeze
