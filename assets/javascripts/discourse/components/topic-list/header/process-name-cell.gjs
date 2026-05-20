import SortableColumn from "discourse/components/topic-list/header/sortable-column";

const ProcessNameCell = <template>
  <SortableColumn
    @sortable={{@sortable}}
    @number="false"
    @order="process-name"
    @activeOrder={{@activeOrder}}
    @changeSort={{@changeSort}}
    @ascending={{@ascending}}
    @name="process-name"
  />
</template>;

export default ProcessNameCell;
