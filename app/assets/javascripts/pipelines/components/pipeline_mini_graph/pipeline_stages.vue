<script>
import PipelineStage from './pipeline_stage.vue';
/**
 * Renders the pipeline stages portion of the pipeline mini graph.
 */
export default {
  components: {
    PipelineStage,
  },
  props: {
    stages: {
      type: Array,
      required: true,
    },
    updateDropdown: {
      type: Boolean,
      required: false,
      default: false,
    },
    stagesClass: {
      type: [Array, Object, String],
      required: false,
      default: '',
    },
    isMergeTrain: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  methods: {
    onPipelineActionRequestComplete() {
      this.$emit('pipelineActionRequestComplete');
    },
  },
};
</script>
<template>
  <div data-testid="pipeline-stages" class="gl-display-inline gl-vertical-align-middle">
    <div
      v-for="stage in stages"
      :key="stage.name"
      :class="stagesClass"
      class="dropdown gl-display-inline-block gl-mr-2 gl-my-2 gl-vertical-align-middle stage-container"
    >
      <pipeline-stage
        :stage="stage"
        :update-dropdown="updateDropdown"
        :is-merge-train="isMergeTrain"
        @pipelineActionRequestComplete="onPipelineActionRequestComplete"
        @miniGraphStageClick="$emit('miniGraphStageClick')"
      />
    </div>
  </div>
</template>
